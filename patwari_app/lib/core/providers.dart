import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patwari_app/core/dio_client.dart';

final dioClientProvider = Provider((ref) => DioClient());
