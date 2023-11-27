
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:imclient/imclient.dart';
import 'package:rtckit/conference/conference_delegate.dart';
import 'package:rtckit/conference/converence_info.dart';

import 'config.dart';

typedef AppServerErrorCallback = Function(String msg);
typedef AppServerLoginSuccessCallback = Function(String userId, String token, bool isNewUser);

typedef AppServerHTTPCallback = Function(String response);
class AppServer implements ConferenceDelegate {
  static final AppServer _instance = AppServer();
  static AppServer Instance() {
    return _instance;
  }

  String? _authToken;
  void sendCode(String phoneNum, Function successCallback, AppServerErrorCallback errorCallback) {
    String jsonStr = json.encode({'mobile':phoneNum});
    postJson('/send_code', jsonStr, (response) {
      Map<dynamic, dynamic> map = json.decode(response);
      if(map['code'] == 0) {
        successCallback();
      } else {
        errorCallback(map['message'] ?? '网络错误');
      }
    }, errorCallback);
  }

  void login(String phoneNum, String smsCode, AppServerLoginSuccessCallback successCallback, AppServerErrorCallback errorCallback) async {
    String jsonStr = json.encode({'mobile':phoneNum, 'code':smsCode, 'clientId':await Imclient.clientId, 'platform': 2});
    postJson('/login', jsonStr, (response) {

      Map<dynamic, dynamic> map = json.decode(response);
      if(map['code'] == 0) {
        Map<dynamic, dynamic> result = map['result'];
        String userId = result['userId'];
        String token = result['token'];
        bool newUser = result['register'];
        successCallback(userId, token, newUser);
      } else {
        errorCallback(map['message'] ?? '网络错误');
      }
    }, errorCallback);
  }

  void postJson(String request, String? json, AppServerHTTPCallback successCallback, AppServerErrorCallback errorCallback) async {
    var url = Config.APP_Server_Address + request;

    http.Response response = await http.post(
        Uri.parse(url), // post地址
        headers: {"content-type": "application/json"}, //设置content-type为json
        body: json //json参数
    );

    if(response.statusCode != 200) {
      errorCallback(response.body);
    } else {
      _authToken = response.headers['authtoken'];
      successCallback(response.body);
    }
  }
  Map<String, Object> _conferenceInfo2Map(ConferenceInfo info) {
    Map<String, Object> dict = {};
    dict["conferenceId"] = info.conferenceId;
    if(info.conferenceTitle != null) {
      dict["conferenceTitle"] = info.conferenceTitle!;
    }
    if(info.password != null) {
      dict["password"] = info.password!;
    }
    if(info.pin != null) {
      dict["pin"] = info.pin!;
    }
    dict["owner"] = info.owner;
    dict["managers"] = info.managers;
    if(info.focus != null) {
      dict["focus"] = info.focus!;
    }
    dict["startTime"] = (info.startTime);
    dict["endTime"] = (info.endTime);
    dict["audience"] = (info.audience);
    dict["advance"] = (info.advance);
    dict["allowSwitchMode"] = (info.allowTurnOnMic);
    dict["noJoinBeforeStart"] = (info.noJoinBeforeStart);
    dict["recording"] = (info.recording);
    dict["maxParticipants"] = (info.maxParticipants);
    return dict;
  }

  ConferenceInfo? _conferenceInfoFromMap(Map<dynamic, dynamic> dictionary) {
    String? conferenceId = dictionary["conferenceId"] as String?;
    String? owner = dictionary["owner"] as String?;
    if(conferenceId == null || owner == null) {
      return null;
    }
    ConferenceInfo info = ConferenceInfo(conferenceId, owner);

    info.conferenceTitle = dictionary["conferenceTitle"] as String?;
    info.password = dictionary["password"] as String?;
    info.pin = dictionary["pin"] as String?;
    if(dictionary["managers"] != null && dictionary["managers"] is List<String>) {
      info.managers = (dictionary["managers"] as List<String>);
    }

    info.focus = dictionary["focus"] as String?;
    info.startTime = dictionary["startTime"] as int;
    info.endTime = dictionary["endTime"] as int;
    info.audience = dictionary["audience"] as bool;
    info.advance = dictionary["advance"]  as bool;
    info.allowTurnOnMic = dictionary["allowSwitchMode"] as bool;
    info.noJoinBeforeStart = dictionary["noJoinBeforeStart"] as bool;
    info.recording = dictionary["recording"] as bool;
    info.maxParticipants = dictionary["maxParticipants"] as int;

    return info;
  }

  @override
  void createConference(ConferenceInfo conferenceInfo, ConferenceStringSuccessCallback successBlock, void Function(int errorCode, String message) errorBlock) {
    postJson("/conference/create", json.encode(_conferenceInfo2Map(conferenceInfo)), (response) {
      Map<dynamic, dynamic> map = json.decode(response);
      if(map['code'] == 0) {
        String conferenceId = map['result'] as String;
        successBlock(conferenceId);
      } else {
        errorBlock(map['code'], "failure");
      }
    }, (msg) {
      errorBlock(-1, msg);
    });
  }

  @override
  void destroyConference(String conferenceId, ConferenceVoidSuccessCallback successBlock, void Function(int errorCode, String message) errorBlock) {
    postJson('/conference/destroy/$conferenceId', null, (response) {
      Map<dynamic, dynamic> map = json.decode(response);
      if(map['code'] == 0) {
        successBlock();
      } else {
        errorBlock(map['code'], "failure");
      }
    }, (msg) {
      errorBlock(-1, msg);
    });
  }

  @override
  void favConference(String conferenceId, ConferenceVoidSuccessCallback successBlock, void Function(int errorCode, String message) errorBlock) {
    postJson('/conference/fav/$conferenceId', null, (response) {
      Map<dynamic, dynamic> map = json.decode(response);
      if(map['code'] == 0) {
        successBlock();
      } else {
        errorBlock(map['code'], "failure");
      }
    }, (msg) {
      errorBlock(-1, msg);
    });
  }

  @override
  void focusConference(String conferenceId, String? userId, ConferenceVoidSuccessCallback successBlock, void Function(int errorCode, String message) errorBlock) {
    postJson('/conference/focus/$conferenceId', json.encode({'userId':userId??""}), (response) {
      Map<dynamic, dynamic> map = json.decode(response);
      if(map['code'] == 0) {
        successBlock();
      } else {
        errorBlock(map['code'], "failure");
      }
    }, (msg) {
      errorBlock(-1, msg);
    });
  }

  @override
  void getFavConferences(void Function(List<ConferenceInfo> conferenceInfos) successBlock, void Function(int errorCode, String message) errorBlock) {
    postJson('/conference/fav_conferences', null, (response) {
      Map<dynamic, dynamic> map = json.decode(response);
      if(map['code'] == 0) {
        List<Map> result = map['result'];
        List<ConferenceInfo> infos = [];
        for (var value in result) {
          ConferenceInfo? info = _conferenceInfoFromMap(value);
          if(info != null) {
            infos.add(info!);
          }
        }
        successBlock(infos);
      } else {
        errorBlock(map['code'], "failure");
      }
    }, (msg) {
      errorBlock(-1, msg);
    });
  }

  @override
  void getMyPrivateConferenceId(ConferenceStringSuccessCallback successBlock, ConferenceErrorCallback errorBlock) {
    postJson('/conference/get_my_id', null, (response) {
      Map<dynamic, dynamic> map = json.decode(response);
      if(map['code'] == 0) {
        String conferenceId = map['result'] as String;
        successBlock(conferenceId);
      } else {
        errorBlock(map['code'], "failure");
      }
    }, (msg) {
      errorBlock(-1, msg);
    });
  }

  @override
  void isFavConference(String conferenceId, void Function(bool isFav) successBlock, void Function(int errorCode, String message) errorBlock) {
    postJson('/conference/is_fav/$conferenceId', null, (response) {
      Map<dynamic, dynamic> map = json.decode(response);
      if(map['code'] == 0) {
        successBlock(true);
      } else if(map['code'] == 16) {
        successBlock(false);
      } else {
        errorBlock(map['code'], "failure");
      }
    }, (msg) {
      errorBlock(-1, msg);
    });
  }

  @override
  void queryConferenceInfo(String conferenceId, String? password, void Function(ConferenceInfo conferenceInfo) successBlock, void Function(int errorCode, String message) errorBlock) {
    late Map request = {"conferenceId":conferenceId};
    if(password != null && password != '') {
      request['password'] = password;
    }
    postJson('/conference/info', json.encode(request), (response) {
      Map<dynamic, dynamic> map = json.decode(response);
      if(map['code'] == 0) {
        Map dict = map['result'];
        var info = _conferenceInfoFromMap(dict);
        if(info != null) {
          successBlock(info);
        } else {
          errorBlock(-1, "not exist");
        }
      } else {
        errorBlock(map['code'], "failure");
      }
    }, (msg) {
      errorBlock(-1, msg);
    });
  }

  @override
  void recordConference(String conferenceId, bool record, ConferenceVoidSuccessCallback successBlock, void Function(int errorCode, String message) errorBlock) {
    postJson('/conference/recording/$conferenceId', json.encode({'recoring':record}), (response) {
      Map<dynamic, dynamic> map = json.decode(response);
      if(map['code'] == 0) {
        successBlock();
      } else {
        errorBlock(map['code'], "failure");
      }
    }, (msg) {
      errorBlock(-1, msg);
    });
  }

  @override
  void unfavConference(String conferenceId, ConferenceVoidSuccessCallback successBlock, void Function(int errorCode, String message) errorBlock) {
    postJson('/conference/unfav/$conferenceId', null, (response) {
      Map<dynamic, dynamic> map = json.decode(response);
      if(map['code'] == 0) {
        successBlock();
      } else {
        errorBlock(map['code'], "failure");
      }
    }, (msg) {
      errorBlock(-1, msg);
    });
  }

  @override
  void updateConference(ConferenceInfo conferenceInfo, ConferenceVoidSuccessCallback successBlock, void Function(int errorCode, String message) errorBlock) {
    postJson('/conference/put_info', jsonEncode(_conferenceInfo2Map(conferenceInfo)), (response) {
      Map<dynamic, dynamic> map = json.decode(response);
      if(map['code'] == 0) {
        successBlock();
      } else {
        errorBlock(map['code'], "failure");
      }
    }, (msg) {
      errorBlock(-1, msg);
    });
  }
}