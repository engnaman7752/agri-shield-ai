const apiBaseUrl = '/api/';
let statsData = {};
let claimsData = [];
let sensorsData = [];

// DOM Elements
const navItems = document.querySelectorAll('.nav-item');
const tabContents = document.querySelectorAll('.tab-content');
const pageTitle = document.getElementById('page-title');
const refreshBtn = document.getElementById('refresh-btn');

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    initTabs();
    fetchStats();
    fetchClaims();
    fetchSensors();

    refreshBtn.addEventListener('click', () => {
        const icon = refreshBtn.querySelector('i');
        icon.classList.add('spin');
        Promise.all([fetchStats(), fetchClaims(), fetchSensors()]).finally(() => {
            setTimeout(() => icon.classList.remove('spin'), 1000);
        });
    });
});

// Tab Management
function initTabs() {
    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            const tab = item.getAttribute('data-tab');

            // UI Update
            navItems.forEach(i => i.classList.remove('active'));
            item.classList.add('active');

            tabContents.forEach(content => {
                content.classList.remove('active');
                if (content.id === `${tab}-tab`) {
                    content.classList.add('active');
                }
            });

            pageTitle.innerText = item.querySelector('span').innerText;
        });
    });
}

// Data Fetching
async function fetchStats() {
    try {
        const res = await fetch(`${apiBaseUrl}admin/stats`);
        const json = await res.json();
        if (json.success) {
            statsData = json.data;
            updateStatsUI();
            updateChart();
        }
    } catch (e) {
        console.error('Stats fetch error:', e);
    }
}

async function fetchClaims() {
    try {
        const res = await fetch(`${apiBaseUrl}admin/claims`);
        const json = await res.json();
        if (json.success) {
            claimsData = json.data;
            updateClaimsUI();
        }
    } catch (e) {
        console.error('Claims fetch error:', e);
    }
}

async function fetchSensors() {
    try {
        const res = await fetch(`${apiBaseUrl}patwari/sensors/available`);
        const json = await res.json();
        // Since this only returns available, we'll simulate a larger fleet for the admin
        if (json.success) {
            sensorsData = json.data;
            updateSensorsUI();
        }
    } catch (e) {
        console.error('Sensors fetch error:', e);
    }
}

// UI Updates
function updateStatsUI() {
    document.getElementById('stat-farmers').innerText = statsData.totalFarmers || 0;
    document.getElementById('stat-policies').innerText = statsData.activePolicies || 0;
    document.getElementById('stat-coverage').innerText = '₹' + (statsData.totalCoverage || 0).toLocaleString();
    document.getElementById('stat-pending-claims').innerText = statsData.totalClaims || 0;
}

function updateClaimsUI() {
    const tbody = document.getElementById('claims-table-body');
    tbody.innerHTML = '';

    claimsData.forEach(claim => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>#${claim.policyNumber}</td>
            <td><strong>${claim.damagePercentage ? claim.damagePercentage.toFixed(1) + '%' : 'N/A'}</strong></td>
            <td>${claim.diseaseDetected || 'No disease detected'}</td>
            <td><span class="badge badge-${claim.status.toLowerCase()}">${claim.status}</span></td>
            <td>${new Date(claim.filedAt).toLocaleDateString()}</td>
            <td><button class="btn btn-icon view-claim" data-id="${claim.id}"><i data-lucide="eye"></i></button></td>
        `;
        tbody.appendChild(tr);
    });

    lucide.createIcons();

    // Add detail listeners
    document.querySelectorAll('.view-claim').forEach(btn => {
        btn.addEventListener('click', () => {
            const claimId = btn.getAttribute('data-id');
            const claim = claimsData.find(c => c.id === claimId);
            showClaimModal(claim);
        });
    });
}

function updateSensorsUI() {
    const container = document.getElementById('sensor-grid-container');
    container.innerHTML = '';

    // Total stats
    document.getElementById('stat-sensor-total').innerText = statsData.sensorCount || 0;
    document.getElementById('stat-sensor-available').innerText = statsData.availableSensors || 0;
    document.getElementById('stat-sensor-online').innerText = (statsData.sensorCount - statsData.availableSensors) || 0;

    // We'll show a sample of sensors
    const sampleSize = 12;
    for (let i = 0; i < sampleSize; i++) {
        const isActive = i < (statsData.sensorCount - statsData.availableSensors);
        const card = document.createElement('div');
        card.className = `sensor-card ${isActive ? 'active' : ''}`;
        card.innerHTML = `
            <i data-lucide="cpu"></i>
            <h4>SENS-00${i + 1}</h4>
            <p>${isActive ? 'Online / Transmitting' : 'In Warehouse'}</p>
        `;
        container.appendChild(card);
    }
    lucide.createIcons();
}

function showClaimModal(claim) {
    const modal = document.getElementById('claim-modal');
    const body = document.getElementById('modal-body-content');

    const imageHtml = claim.imageUrls && claim.imageUrls.length > 0
        ? `<div class="image-gallery">${claim.imageUrls.map(url => `<img src="${url}" alt="Crop image">`).join('')}</div>`
        : '<p>No images available</p>';

    body.innerHTML = `
        <div class="claim-detail-grid">
            <div class="info-pane">
                <h4>Farmer Context</h4>
                <p><strong>Policy:</strong> ${claim.policyNumber}</p>
                <p><strong>Status:</strong> ${claim.status}</p>
                <hr>
                <h4 style="margin-top:20px">AI Assessment Details</h4>
                <div class="ai-reasoning">
                    <p><strong>Disease Detected:</strong> ${claim.diseaseDetected || 'None'}</p>
                    <p><strong>Severity Score:</strong> ${claim.damagePercentage ? claim.damagePercentage.toFixed(2) : 0}%</p>
                    <p><strong>Model Version:</strong> ${claim.modelVersion || 'v1.2.0'}</p>
                </div>
                <h4 style="margin-top:20px">Calculated Payout</h4>
                <h2 style="color:var(--primary)">₹${(claim.claimAmount || 0).toLocaleString()}</h2>
            </div>
            <div class="gallery-pane">
                <h4>Uploaded Field Photos</h4>
                ${imageHtml}
            </div>
        </div>
    `;

    modal.style.display = 'block';

    const closeBtn = modal.querySelector('.close-modal');
    closeBtn.onclick = () => modal.style.display = 'none';
    window.onclick = (e) => { if (e.target === modal) modal.style.display = 'none'; };
}

// Charting
let trendsChart;
function updateChart() {
    const ctx = document.getElementById('trendsChart').getContext('2d');
    if (trendsChart) trendsChart.destroy();

    trendsChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: ['Week 1', 'Week 2', 'Week 3', 'Current'],
            datasets: [
                {
                    label: 'Policies Issued',
                    data: [12, 19, 3, 5 + (statsData.activePolicies || 0)],
                    borderColor: '#10b981',
                    tension: 0.4,
                    fill: true,
                    backgroundColor: 'rgba(16, 185, 129, 0.1)'
                },
                {
                    label: 'Claims Filed',
                    data: [2, 5, 1, statsData.totalClaims || 0],
                    borderColor: '#ef4444',
                    tension: 0.4,
                    fill: false
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { position: 'bottom' }
            },
            scales: {
                y: { beginAtZero: true, grid: { color: '#f1f5f9' } },
                x: { grid: { display: false } }
            }
        }
    });
}
