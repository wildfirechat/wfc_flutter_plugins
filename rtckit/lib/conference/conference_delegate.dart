import 'package:rtckit/conference/converence_info.dart';


typedef ConferenceErrorCallback = void Function(int errorCode, String message);
typedef ConferenceStringSuccessCallback = void Function(String strValue);
typedef ConferenceVoidSuccessCallback = void Function();

abstract class ConferenceDelegate {
  void getMyPrivateConferenceId(ConferenceStringSuccessCallback successBlock, ConferenceErrorCallback errorBlock);

  void createConference(ConferenceInfo conferenceInfo, ConferenceStringSuccessCallback successBlock, void Function(int errorCode, String message) errorBlock);

  void updateConference(ConferenceInfo conferenceInfo, ConferenceVoidSuccessCallback successBlock, void Function(int errorCode, String message) errorBlock);

  void recordConference(String conferenceId, bool record, ConferenceVoidSuccessCallback successBlock, void Function(int errorCode, String message) errorBlock);

  void focusConference(String conferenceId, String? userId, ConferenceVoidSuccessCallback successBlock, void Function(int errorCode, String message) errorBlock);

  void queryConferenceInfo(String conferenceId, String? password, void Function(ConferenceInfo conferenceInfo) successBlock, void Function(int errorCode, String message) errorBlock);

  void destroyConference(String conferenceId, ConferenceVoidSuccessCallback successBlock, void Function(int errorCode, String message) errorBlock);

  void favConference(String conferenceId, ConferenceVoidSuccessCallback successBlock, void Function(int errorCode, String message) errorBlock);

  void unfavConference(String conferenceId, ConferenceVoidSuccessCallback successBlock, void Function(int errorCode, String message) errorBlock);

  void isFavConference(String conferenceId, void Function(bool isFav) successBlock, void Function(int errorCode, String message) errorBlock);

  void getFavConferences( void Function(List<ConferenceInfo> conferenceInfos) successBlock, void Function(int errorCode, String message) errorBlock);
}