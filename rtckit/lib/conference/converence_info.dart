class ConferenceInfo {
  String conferenceId;
  String? conferenceTitle;
  String? password;
  String? pin;
  String owner;
  late List<String> managers;
  String? focus;
  late int startTime;
  late int endTime;
  late bool audience;
  late bool advance;
  late bool allowTurnOnMic;
  late bool noJoinBeforeStart;
  late bool recording;
  late int maxParticipants;

  ConferenceInfo(this.conferenceId, this.owner,
      {
        this.startTime = 0,
        this.endTime = 0,
        this.audience = false,
        this.advance = false,
        this.allowTurnOnMic = false,
        this.noJoinBeforeStart = false,
        this.recording = false,
        this.maxParticipants = 9}) {
    managers = [];
  }
}