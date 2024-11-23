import 'package:universal_html/html.dart' as html;

void downloadFileOnBrowser() async {
  final file = html.File([await html.HttpRequest.request('recording.wav', responseType: 'blob').then((response) => response.response)], 'recording.wav');
  final url = html.Url.createObjectUrlFromBlob(file);
  html.AnchorElement(href: url)
    ..setAttribute('download', 'recording.wav')
    ..click();
  html.Url.revokeObjectUrl(url);
}
