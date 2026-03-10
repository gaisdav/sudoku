// На Web и десктопе реклама не поддерживается — используется заглушка.
// ignore: uri_does_not_exist
export 'ads_platform_stub.dart'
    if (dart.library.io) 'ads_platform_io.dart';
