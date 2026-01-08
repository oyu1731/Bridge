class SpeechWrapper {
  constructor() {
    console.log("[JS] SpeechWrapper constructor");
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    this.recognition = new SpeechRecognition();
    this.recognition.lang = 'ja-JP';
    this.recognition.interimResults = true;
    this.recognition.continuous = true;

    this.onResultCallback = null;

    this.permanentTranscript = "";  // 全テキストを保存
    this.latestText = "";           // interim用（途中経過）

    this.silenceTimer = null;
    this.SILENCE_LIMIT = 20000;
    this._forcedStop = false;
    console.log("[JS] Initial _forcedStop:", this._forcedStop);

    this.recognition.onresult = (event) => {
      let text = "";
      for (let i = event.resultIndex; i < event.results.length; i++) {
        text += event.results[i][0].transcript;
      }

      // interim か final か判定
      const last = event.results[event.results.length - 1];
      if (last.isFinal) {
        // final が来たときに permanentTranscript に加える
        this.permanentTranscript += text + " ";
        this.latestText = this.permanentTranscript;
      } else {
        // interim は latestText に反映
        this.latestText = this.permanentTranscript + text;
      }

      console.log("[JS] permanent:", this.permanentTranscript);
      console.log("[JS] latest:", this.latestText);

      // Flutter に送る内容は latestText（常に全部入り）
      if (this.onResultCallback) {
        this.onResultCallback(this.latestText);
      }

      console.log("[JS] Resetting silence timer from onresult.");
      this.resetSilenceTimer();
    };

    this.recognition.onend = () => {
      console.warn("[JS] recognition ended. _forcedStop:", this._forcedStop);

      if (this._forcedStop) {
        console.log("[JS] Recognition stopped by force, not restarting.");
        return;
      }

      // Chromeが勝手に止める対策
      console.log("[JS] Recognition ended automatically, auto restarting.");
      this.recognition.start();
    };
  }

  start(callback) {
    console.log("[JS] start called. Current permanentTranscript:", this.permanentTranscript);
    this.onResultCallback = callback;
    this._forcedStop = false; // startが呼ばれるたびに_forcedStopをリセット
    
    // 新しいセッション開始時に以前の文字起こしをクリア
    this.permanentTranscript = ""; 
    this.latestText = "";

    this.recognition.start();
    console.log("[JS] Resetting silence timer from start. permanentTranscript cleared.");
    this.resetSilenceTimer();
    
    // 音声認識開始時に既存のテキストをFlutterに送る
    if (this.onResultCallback) {
      this.onResultCallback(this.latestText);
    }
  }

  stop() {
    console.log("[JS] stop called. Setting _forcedStop to true.");
    this._forcedStop = true;
    console.log("[JS] Clearing silence timer from stop.");
    clearTimeout(this.silenceTimer);
    this.recognition.stop();

    // stop 時も permanentTranscript を残す
    if (this.onResultCallback) {
      this.onResultCallback(this.permanentTranscript.trim());
    }
  }

  resetSilenceTimer() {
    console.log("[JS] Clearing existing silence timer.");
    clearTimeout(this.silenceTimer);
    this.silenceTimer = setTimeout(() => {
      console.log("[JS] Silence limit reached (20s) → calling stop().");
      this.stop();
    }, this.SILENCE_LIMIT);
  }

  playAudio(base64Audio) {
    console.log("[JS] playAudio called with base64 data.");
    const audio = new Audio();
    audio.src = 'data:audio/wav;base64,' + base64Audio;
    audio.play()
      .then(() => console.log("[JS] Audio playback started."))
      .catch(error => console.error("[JS] Audio playback error:", error));
  }
}

window.speechWrapper = new SpeechWrapper();
console.log("[JS] speechWrapper initialized:", window.speechWrapper);