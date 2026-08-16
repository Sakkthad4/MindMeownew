import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  thai('th', 'ไทย'),
  chinese('zh', '中文'),
  english('en', 'English');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  Locale get locale => Locale(code);
}

class AppLanguageController {
  AppLanguageController._();

  static const _preferenceKey = 'app_language';
  static final ValueNotifier<AppLanguage> current = ValueNotifier<AppLanguage>(
    AppLanguage.thai,
  );

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedCode = preferences.getString(_preferenceKey);
    current.value = AppLanguage.values.firstWhere(
      (language) => language.code == savedCode,
      orElse: () => AppLanguage.thai,
    );
  }

  static Future<void> change(AppLanguage language) async {
    if (current.value == language) return;
    current.value = language;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, language.code);
  }
}

class AppText {
  AppText._();

  static const Map<String, Map<AppLanguage, String>> _translations = {
    'chooseLanguage': {
      AppLanguage.thai: 'เลือกภาษา',
      AppLanguage.chinese: '选择语言',
      AppLanguage.english: 'Choose language',
    },
    'start': {
      AppLanguage.thai: 'เริ่ม',
      AppLanguage.chinese: '开始',
      AppLanguage.english: 'START',
    },
    'exercises': {
      AppLanguage.thai: 'ออกกำลังกาย',
      AppLanguage.chinese: '运动',
      AppLanguage.english: 'Exercises',
    },
    'games': {
      AppLanguage.thai: 'เกม',
      AppLanguage.chinese: '游戏',
      AppLanguage.english: 'Games',
    },
    'mindTalk': {
      AppLanguage.thai: 'พูดคุย',
      AppLanguage.chinese: '聊天',
      AppLanguage.english: 'MindTalk',
    },
    'healthCare': {
      AppLanguage.thai: 'สุขภาพ',
      AppLanguage.chinese: '健康管理',
      AppLanguage.english: 'Health Care',
    },
    'go': {
      AppLanguage.thai: 'ไปเลย!',
      AppLanguage.chinese: '进入！',
      AppLanguage.english: 'GO!',
    },
    'cancel': {
      AppLanguage.thai: 'ยกเลิก',
      AppLanguage.chinese: '取消',
      AppLanguage.english: 'Cancel',
    },
    'supermarket': {
      AppLanguage.thai: 'MindCart',
      AppLanguage.chinese: 'MindCart',
      AppLanguage.english: 'MindCart',
    },
    'diceDash': {
      AppLanguage.thai: 'เกมคำนวณ',
      AppLanguage.chinese: '计算游戏',
      AppLanguage.english: 'Dice Dash',
    },
    'catPaw': {
      AppLanguage.thai: 'QuickPaw',
      AppLanguage.chinese: 'QuickPaw',
      AppLanguage.english: 'QuickPaw',
    },
    'draw': {
      AppLanguage.thai: 'Drawit',
      AppLanguage.chinese: 'Drawit',
      AppLanguage.english: 'Drawit',
    },
    'morningStretch': {
      AppLanguage.thai: 'ยืดเหยียดตอนเช้า',
      AppLanguage.chinese: '晨间拉伸',
      AppLanguage.english: 'Morning Stretch',
    },
    'dance': {
      AppLanguage.thai: 'เต้น',
      AppLanguage.chinese: '跳舞',
      AppLanguage.english: 'Dance',
    },
    'memoryGame': {
      AppLanguage.thai: 'เกมฝึกความจำ',
      AppLanguage.chinese: '记忆游戏',
      AppLanguage.english: 'Memory Game',
    },
    'calculatingGame': {
      AppLanguage.thai: 'เกมคำนวณ',
      AppLanguage.chinese: '计算游戏',
      AppLanguage.english: 'Calculating Game',
    },
    'reactionGame': {
      AppLanguage.thai: 'เกมทดสอบการตอบสนอง',
      AppLanguage.chinese: '反应速度游戏',
      AppLanguage.english: 'Reaction Time Game',
    },
    'drawingGame': {
      AppLanguage.thai: 'Drawit',
      AppLanguage.chinese: 'Drawit',
      AppLanguage.english: 'Drawit',
    },
    'easy': {
      AppLanguage.thai: 'ง่าย',
      AppLanguage.chinese: '简单',
      AppLanguage.english: 'Easy',
    },
    'normal': {
      AppLanguage.thai: 'ปกติ',
      AppLanguage.chinese: '普通',
      AppLanguage.english: 'Normal',
    },
    'hard': {
      AppLanguage.thai: 'ยาก',
      AppLanguage.chinese: '困难',
      AppLanguage.english: 'Hard',
    },
    'difficulty': {
      AppLanguage.thai: 'ระดับ',
      AppLanguage.chinese: '难度',
      AppLanguage.english: 'Difficulty',
    },
    'memorizeTime': {
      AppLanguage.thai: 'เวลาจดจำ',
      AppLanguage.chinese: '记忆时间',
      AppLanguage.english: 'MEMORIZE TIME',
    },
    'startShopping': {
      AppLanguage.thai: 'เริ่มซื้อของ',
      AppLanguage.chinese: '开始购物',
      AppLanguage.english: 'Start Shopping',
    },
    'cart': {
      AppLanguage.thai: 'ตะกร้า',
      AppLanguage.chinese: '购物车',
      AppLanguage.english: 'CART',
    },
    'cook': {
      AppLanguage.thai: 'ทำอาหาร!',
      AppLanguage.chinese: '烹饪！',
      AppLanguage.english: 'COOK!',
    },
    'result': {
      AppLanguage.thai: 'ผลลัพธ์',
      AppLanguage.chinese: '结果',
      AppLanguage.english: 'Result',
    },
    'yourDrawing': {
      AppLanguage.thai: 'ภาพวาดของคุณ',
      AppLanguage.chinese: '你的画',
      AppLanguage.english: 'Your Drawing',
    },
    'accuracy': {
      AppLanguage.thai: 'ความแม่นยำ',
      AppLanguage.chinese: '准确率',
      AppLanguage.english: 'Accuracy',
    },
    'playAgain': {
      AppLanguage.thai: 'เล่นอีกครั้ง',
      AppLanguage.chinese: '再玩一次',
      AppLanguage.english: 'Play Again',
    },
    'back': {
      AppLanguage.thai: 'ย้อนกลับ',
      AppLanguage.chinese: '返回',
      AppLanguage.english: 'Back',
    },
    'home': {
      AppLanguage.thai: 'หน้าหลัก',
      AppLanguage.chinese: '主页',
      AppLanguage.english: 'Home',
    },
    'excellent': {
      AppLanguage.thai: 'ยอดเยี่ยม',
      AppLanguage.chinese: '优秀',
      AppLanguage.english: 'Excellent',
    },
    'good': {
      AppLanguage.thai: 'ดี',
      AppLanguage.chinese: '很好',
      AppLanguage.english: 'Good',
    },
    'okay': {
      AppLanguage.thai: 'พอใช้',
      AppLanguage.chinese: '不错',
      AppLanguage.english: 'Okay',
    },
    'keepTrying': {
      AppLanguage.thai: 'พยายามต่อไป',
      AppLanguage.chinese: '继续努力',
      AppLanguage.english: 'Keep Trying',
    },
    'great': {
      AppLanguage.thai: 'ดีมาก',
      AppLanguage.chinese: '很棒',
      AppLanguage.english: 'Great',
    },
    'keepGoing': {
      AppLanguage.thai: 'ทำต่อไป',
      AppLanguage.chinese: '继续加油',
      AppLanguage.english: 'Keep Going',
    },
    'tryAgain': {
      AppLanguage.thai: 'ลองอีกครั้ง',
      AppLanguage.chinese: '再试一次',
      AppLanguage.english: 'Try Again',
    },
    'details': {
      AppLanguage.thai: 'รายละเอียด',
      AppLanguage.chinese: '详细信息',
      AppLanguage.english: 'Details',
    },
    'noData': {
      AppLanguage.thai: 'ไม่มีข้อมูล',
      AppLanguage.chinese: '暂无数据',
      AppLanguage.english: 'No data',
    },
    'question': {
      AppLanguage.thai: 'โจทย์',
      AppLanguage.chinese: '题目',
      AppLanguage.english: 'Question',
    },
    'yourAnswer': {
      AppLanguage.thai: 'คำตอบคุณ',
      AppLanguage.chinese: '你的答案',
      AppLanguage.english: 'You',
    },
    'answer': {
      AppLanguage.thai: 'เฉลย',
      AppLanguage.chinese: '答案',
      AppLanguage.english: 'Ans',
    },
    'hits': {
      AppLanguage.thai: 'โดน',
      AppLanguage.chinese: '命中',
      AppLanguage.english: 'HITS',
    },
    'miss': {
      AppLanguage.thai: 'พลาด',
      AppLanguage.chinese: '未命中',
      AppLanguage.english: 'MISS',
    },
    'total': {
      AppLanguage.thai: 'รวม',
      AppLanguage.chinese: '总计',
      AppLanguage.english: 'Total',
    },
    'pawShow': {
      AppLanguage.thai: 'อุ้งเท้าที่แสดง',
      AppLanguage.chinese: '出现次数',
      AppLanguage.english: 'Paw Show',
    },
    'totalPaw': {
      AppLanguage.thai: 'อุ้งเท้าทั้งหมด',
      AppLanguage.chinese: '猫爪总数',
      AppLanguage.english: 'Total Paw',
    },
    'requirement': {
      AppLanguage.thai: 'วัตถุดิบที่ต้องใช้',
      AppLanguage.chinese: '所需食材',
      AppLanguage.english: 'Requirement',
    },
    'missing': {
      AppLanguage.thai: 'ขาด',
      AppLanguage.chinese: '缺少',
      AppLanguage.english: 'Missing',
    },
    'extra': {
      AppLanguage.thai: 'เกิน',
      AppLanguage.chinese: '多余',
      AppLanguage.english: 'Extra',
    },
    'menu': {
      AppLanguage.thai: 'เมนู',
      AppLanguage.chinese: '菜单',
      AppLanguage.english: 'Menu',
    },
    'rolling': {
      AppLanguage.thai: 'กำลังสุ่ม...',
      AppLanguage.chinese: '抽取中...',
      AppLanguage.english: 'Rolling...',
    },
    'roll': {
      AppLanguage.thai: 'สุ่ม',
      AppLanguage.chinese: '抽取',
      AppLanguage.english: 'Roll',
    },
    'retry': {
      AppLanguage.thai: 'ลองอีกครั้ง',
      AppLanguage.chinese: '重试',
      AppLanguage.english: 'Retry',
    },
    'openingCamera': {
      AppLanguage.thai: 'กำลังเปิดกล้อง...',
      AppLanguage.chinese: '正在打开相机...',
      AppLanguage.english: 'Opening camera...',
    },
    'doAgain': {
      AppLanguage.thai: 'ทำอีกครั้ง',
      AppLanguage.chinese: '再做一次',
      AppLanguage.english: 'Do Again',
    },
    'backHome': {
      AppLanguage.thai: 'กลับหน้าหลัก',
      AppLanguage.chinese: '返回主页',
      AppLanguage.english: 'Back to Home',
    },
    'yourScore': {
      AppLanguage.thai: 'คะแนนของคุณ',
      AppLanguage.chinese: '你的分数',
      AppLanguage.english: 'Your score',
    },
    'reminders': {
      AppLanguage.thai: 'การแจ้งเตือน',
      AppLanguage.chinese: '提醒',
      AppLanguage.english: 'Reminders',
    },
    'noReminder': {
      AppLanguage.thai: 'ไม่มีการแจ้งเตือน',
      AppLanguage.chinese: '暂无提醒',
      AppLanguage.english: 'No reminder',
    },
    'save': {
      AppLanguage.thai: 'บันทึก',
      AppLanguage.chinese: '保存',
      AppLanguage.english: 'Save',
    },
    'overviewScore': {
      AppLanguage.thai: 'ภาพรวมคะแนน',
      AppLanguage.chinese: '分数概览',
      AppLanguage.english: 'Overview Score',
    },
    'game': {
      AppLanguage.thai: 'เกม',
      AppLanguage.chinese: '游戏',
      AppLanguage.english: 'Game',
    },
    'catBondXp': {
      AppLanguage.thai: 'ค่าความผูกพันกับแมว',
      AppLanguage.chinese: '猫咪亲密度',
      AppLanguage.english: 'Cat Bond XP',
    },
    'cognitiveDomains': {
      AppLanguage.thai: 'ทักษะการคิด',
      AppLanguage.chinese: '认知能力',
      AppLanguage.english: 'Cognitive Domains',
    },
    'memoryDomain': {
      AppLanguage.thai: 'ความจำ',
      AppLanguage.chinese: '记忆力',
      AppLanguage.english: 'Memory',
    },
    'attentionDomain': {
      AppLanguage.thai: 'สมาธิและความสนใจ',
      AppLanguage.chinese: '注意力',
      AppLanguage.english: 'Attention',
    },
    'executiveFunctionDomain': {
      AppLanguage.thai: 'การคิดและวางแผน',
      AppLanguage.chinese: '执行功能',
      AppLanguage.english: 'Executive Function',
    },
    'visuospatialDomain': {
      AppLanguage.thai: 'การรับรู้มิติสัมพันธ์',
      AppLanguage.chinese: '视觉空间能力',
      AppLanguage.english: 'Visuospatial',
    },
    'languageDomain': {
      AppLanguage.thai: 'การใช้ภาษา',
      AppLanguage.chinese: '语言参与',
      AppLanguage.english: 'Language',
    },
    'socialCognitionDomain': {
      AppLanguage.thai: 'การรับรู้อารมณ์และสังคม',
      AppLanguage.chinese: '社会情绪认知',
      AppLanguage.english: 'Social Cognition',
    },
    'cognitiveIndicatorNote': {
      AppLanguage.thai:
          'ตัวชี้วัดจากกิจกรรมจริง ไม่ใช่ผลวินิจฉัยหรือแบบทดสอบทางคลินิก',
      AppLanguage.chinese: '指标来自实际活动，不属于临床评估或诊断',
      AppLanguage.english:
          'Activity-derived indicators—not a clinical test or diagnosis.',
    },
    'noCognitiveDataForPeriod': {
      AppLanguage.thai:
          'ยังไม่มีกิจกรรมในช่วงเวลานี้ ลองเลือกช่วงเวลาอื่นหรือทำกิจกรรมให้สำเร็จ',
      AppLanguage.chinese: '此时间段暂无活动，请选择其他时间或先完成一项活动',
      AppLanguage.english:
          'No activity in this period. Choose another period or complete an activity.',
    },
    'hour': {
      AppLanguage.thai: 'ชั่วโมง',
      AppLanguage.chinese: '小时',
      AppLanguage.english: 'Hour',
    },
    'day': {
      AppLanguage.thai: 'วัน',
      AppLanguage.chinese: '天',
      AppLanguage.english: 'Day',
    },
    'week': {
      AppLanguage.thai: 'สัปดาห์',
      AppLanguage.chinese: '周',
      AppLanguage.english: 'Week',
    },
    'month': {
      AppLanguage.thai: 'เดือน',
      AppLanguage.chinese: '月',
      AppLanguage.english: 'Month',
    },
    'previousPeriod': {
      AppLanguage.thai: 'ช่วงก่อนหน้า',
      AppLanguage.chinese: '上一时段',
      AppLanguage.english: 'Previous period',
    },
    'nextPeriod': {
      AppLanguage.thai: 'ช่วงถัดไป',
      AppLanguage.chinese: '下一时段',
      AppLanguage.english: 'Next period',
    },
    'overall': {
      AppLanguage.thai: 'ภาพรวม',
      AppLanguage.chinese: '总览',
      AppLanguage.english: 'Overall',
    },
    'connecting': {
      AppLanguage.thai: 'กำลังเชื่อมต่อ...',
      AppLanguage.chinese: '正在连接...',
      AppLanguage.english: 'Connecting...',
    },
    'reset': {
      AppLanguage.thai: 'เริ่มใหม่',
      AppLanguage.chinese: '重置',
      AppLanguage.english: 'Reset',
    },
    'statistics': {
      AppLanguage.thai: 'สถิติ',
      AppLanguage.chinese: '统计',
      AppLanguage.english: 'Statistics',
    },
    'exercise': {
      AppLanguage.thai: 'การออกกำลังกาย',
      AppLanguage.chinese: '运动',
      AppLanguage.english: 'Exercise',
    },
    'addReminder': {
      AppLanguage.thai: 'เพิ่มการแจ้งเตือน',
      AppLanguage.chinese: '添加提醒',
      AppLanguage.english: 'Add Reminder',
    },
    'title': {
      AppLanguage.thai: 'ชื่อเรื่อง',
      AppLanguage.chinese: '标题',
      AppLanguage.english: 'Title',
    },
    'note': {
      AppLanguage.thai: 'หมายเหตุ',
      AppLanguage.chinese: '备注',
      AppLanguage.english: 'Note',
    },
    'greatCompleted': {
      AppLanguage.thai: 'เยี่ยมมาก! เสร็จสิ้นแล้ว 🎉',
      AppLanguage.chinese: '太棒了！已完成 🎉',
      AppLanguage.english: 'Great! Completed 🎉',
    },
    'cameraFailed': {
      AppLanguage.thai: 'เปิดกล้องไม่สำเร็จ',
      AppLanguage.chinese: '无法打开相机',
      AppLanguage.english: 'Could not open camera',
    },
    'holdPose': {
      AppLanguage.thai: 'ค้างไว้! ทำได้ดีมาก 👍',
      AppLanguage.chinese: '保持住！做得很好 👍',
      AppLanguage.english: 'Hold it! Great job 👍',
    },
    'exerciseSafety': {
      AppLanguage.thai: 'เคลื่อนไหวช้า ๆ • หายใจปกติ • หยุดทันทีหากเจ็บ',
      AppLanguage.chinese: '慢慢移动 • 正常呼吸 • 感到疼痛请立即停止',
      AppLanguage.english: 'Move slowly • Breathe normally • Stop if it hurts',
    },
    'exerciseStep': {
      AppLanguage.thai: 'ท่า',
      AppLanguage.chinese: '动作',
      AppLanguage.english: 'STEP',
    },
    'exerciseOf': {
      AppLanguage.thai: 'จาก',
      AppLanguage.chinese: '共',
      AppLanguage.english: 'OF',
    },
    'fitBodyInCamera': {
      AppLanguage.thai: 'จัดให้เห็นร่างกายทั้งตัวในกล้อง',
      AppLanguage.chinese: '请让全身都出现在画面中',
      AppLanguage.english: 'Fit your whole body in the camera',
    },
    'keepHoldingPose': {
      AppLanguage.thai: 'ดีมาก! ค้างท่านี้ต่อไป',
      AppLanguage.chinese: '很好！继续保持这个姿势',
      AppLanguage.english: 'Great! Keep holding the pose',
    },
    'conversation': {
      AppLanguage.thai: 'สนทนา',
      AppLanguage.chinese: '对话',
      AppLanguage.english: 'Conversation',
    },
    'selectCatEmotion': {
      AppLanguage.thai: 'เลือกอารมณ์แมว',
      AppLanguage.chinese: '选择猫咪情绪',
      AppLanguage.english: 'Select cat emotion',
    },
    'calm': {
      AppLanguage.thai: 'สงบ',
      AppLanguage.chinese: '平静',
      AppLanguage.english: 'Calm',
    },
    'happy': {
      AppLanguage.thai: 'ดีใจ',
      AppLanguage.chinese: '开心',
      AppLanguage.english: 'Happy',
    },
    'sad': {
      AppLanguage.thai: 'เศร้า',
      AppLanguage.chinese: '难过',
      AppLanguage.english: 'Sad',
    },
    'angry': {
      AppLanguage.thai: 'โกรธ',
      AppLanguage.chinese: '生气',
      AppLanguage.english: 'Angry',
    },
    'neutral': {
      AppLanguage.thai: 'ปกติ',
      AppLanguage.chinese: '平静',
      AppLanguage.english: 'Neutral',
    },
    'anxious': {
      AppLanguage.thai: 'กังวล',
      AppLanguage.chinese: '焦虑',
      AppLanguage.english: 'Anxious',
    },
    'emotionOverview': {
      AppLanguage.thai: 'ภาพรวมอารมณ์ 7 วัน',
      AppLanguage.chinese: '7天情绪概览',
      AppLanguage.english: '7-day emotion overview',
    },
    'conversationSignals': {
      AppLanguage.thai: 'จากบทสนทนา',
      AppLanguage.chinese: '来自对话',
      AppLanguage.english: 'From conversation',
    },
    'cameraObservations': {
      AppLanguage.thai: 'จากกล้อง',
      AppLanguage.chinese: '来自相机',
      AppLanguage.english: 'From camera',
    },
    'noEmotionData': {
      AppLanguage.thai: 'ยังไม่มีข้อมูลอารมณ์ ลองพูดคุยใน MindTalk',
      AppLanguage.chinese: '暂无情绪数据，请先使用 MindTalk',
      AppLanguage.english: 'No emotion data yet. Try talking in MindTalk.',
    },
    'emotionPrivacyNote': {
      AppLanguage.thai: 'บันทึกเฉพาะประเภทอารมณ์ ไม่เก็บภาพหรือข้อความสนทนา',
      AppLanguage.chinese: '仅保存情绪类别，不保存照片或聊天内容',
      AppLanguage.english:
          'Only emotion categories are saved—not photos or conversation text.',
    },
    'emotionEstimateNote': {
      AppLanguage.thai:
          'ผลลัพธ์เป็นเพียงการประมาณ ไม่ใช่การวินิจฉัยทางการแพทย์',
      AppLanguage.chinese: '结果仅为估计，不属于医疗诊断',
      AppLanguage.english:
          'These results are estimates and are not a medical diagnosis.',
    },
    'tapPaw': {
      AppLanguage.thai: 'แตะอุ้งเท้าสีส้มให้เร็ว!',
      AppLanguage.chinese: '快速点击橙色猫爪！',
      AppLanguage.english: 'Tap the orange paw fast!',
    },
    'finish': {
      AppLanguage.thai: 'เสร็จสิ้น',
      AppLanguage.chinese: '完成',
      AppLanguage.english: 'Finish',
    },
    'mindTalkComingSoon': {
      AppLanguage.thai: 'ข้อมูลอารมณ์จาก MindTalk จะแสดงในส่วนนี้',
      AppLanguage.chinese: 'MindTalk 情绪数据将在此处显示',
      AppLanguage.english: 'MindTalk emotion data will appear here',
    },
    'exerciseComingSoon': {
      AppLanguage.thai: 'ประวัติและคะแนนการออกกำลังกายจะแสดงในส่วนนี้',
      AppLanguage.chinese: '运动历史和分数将在此处显示',
      AppLanguage.english: 'Exercise history and scores will appear here',
    },
    'exerciseStatistics': {
      AppLanguage.thai: 'สถิติการยืดเหยียด 7 วัน',
      AppLanguage.chinese: '7天拉伸统计',
      AppLanguage.english: '7-day stretching statistics',
    },
    'exerciseSessions': {
      AppLanguage.thai: 'จำนวนครั้ง',
      AppLanguage.chinese: '训练次数',
      AppLanguage.english: 'Sessions',
    },
    'completedRoutines': {
      AppLanguage.thai: 'ทำครบชุด',
      AppLanguage.chinese: '完成次数',
      AppLanguage.english: 'Completed routines',
    },
    'completedPoses': {
      AppLanguage.thai: 'ท่าที่สำเร็จ',
      AppLanguage.chinese: '完成动作',
      AppLanguage.english: 'Completed poses',
    },
    'completionRate': {
      AppLanguage.thai: 'อัตราทำครบ',
      AppLanguage.chinese: '完成率',
      AppLanguage.english: 'Completion rate',
    },
    'averageScore': {
      AppLanguage.thai: 'คะแนนเฉลี่ย',
      AppLanguage.chinese: '平均分',
      AppLanguage.english: 'Average score',
    },
    'totalExerciseTime': {
      AppLanguage.thai: 'เวลารวม',
      AppLanguage.chinese: '总运动时间',
      AppLanguage.english: 'Total time',
    },
    'weeklyActivity': {
      AppLanguage.thai: 'กิจกรรมในแต่ละวัน',
      AppLanguage.chinese: '每日活动',
      AppLanguage.english: 'Daily activity',
    },
    'noExerciseData': {
      AppLanguage.thai:
          'ยังไม่มีข้อมูล ลองทำท่ายืดเหยียดให้สำเร็จอย่างน้อย 1 ท่า',
      AppLanguage.chinese: '暂无数据，请先完成至少一个拉伸动作',
      AppLanguage.english:
          'No data yet. Complete at least one stretching pose to begin.',
    },
    'minutesShort': {
      AppLanguage.thai: 'นาที',
      AppLanguage.chinese: '分钟',
      AppLanguage.english: 'min',
    },
    'overallSummary': {
      AppLanguage.thai: 'สรุปผลการใช้งานและความผูกพันกับแมว',
      AppLanguage.chinese: '应用使用情况和猫咪亲密度总览',
      AppLanguage.english: 'App activity and cat bond summary',
    },
  };

  static String get(String key) =>
      _translations[key]?[AppLanguageController.current.value] ?? key;

  static String name(String englishName) {
    const gameBrands = <String, String>{
      'supermarket': 'MindCart',
      'catpaw': 'QuickPaw',
      'drawvis': 'Drawit',
    };
    final gameBrand = gameBrands[englishName.toLowerCase()];
    if (gameBrand != null) return gameBrand;

    const names = <String, List<String>>{
      'Chicken': ['ไก่', '鸡肉'],
      'Pork': ['หมู', '猪肉'],
      'Salmon': ['แซลมอน', '三文鱼'],
      'Spaghetti': ['สปาเกตตี', '意大利面'],
      'Rice': ['ข้าว', '米饭'],
      'Bread': ['ขนมปัง', '面包'],
      'Carrot': ['แครอท', '胡萝卜'],
      'Broccoli': ['บรอกโคลี', '西兰花'],
      'Tomato': ['มะเขือเทศ', '番茄'],
      'Onion': ['หัวหอม', '洋葱'],
      'Pepper': ['พริกหวาน', '甜椒'],
      'Potato': ['มันฝรั่ง', '土豆'],
      'Lettuce': ['ผักกาดหอม', '生菜'],
      'Mushroom': ['เห็ด', '蘑菇'],
      'Chicken Bowl': ['ข้าวหน้าไก่', '鸡肉饭'],
      'Veg Salad': ['สลัดผัก', '蔬菜沙拉'],
      'Stir Fry': ['ผัดผัก', '炒菜'],
      'Fried Rice': ['ข้าวผัด', '炒饭'],
      'Salmon Steak': ['สเต๊กแซลมอน', '香煎三文鱼'],
      'Beef Stew': ['สตูเนื้อ', '炖牛肉'],
      'Mix Salad': ['สลัดรวม', '什锦沙拉'],
      'Sandwich': ['แซนด์วิช', '三明治'],
      'Steak': ['สเต๊ก', '牛排'],
      'Cube': ['ลูกบาศก์', '立方体'],
      'Cube Tilt': ['ลูกบาศก์เอียง', '倾斜立方体'],
      'Prism': ['ปริซึม', '棱柱'],
      'Stairs': ['บันได', '楼梯'],
      'L-Block': ['บล็อกตัวแอล', 'L形方块'],
      'House': ['บ้าน', '房子'],
      'Pyramid': ['พีระมิด', '金字塔'],
      'Cylinder': ['ทรงกระบอก', '圆柱体'],
      'Zigzag': ['ซิกแซก', '锯齿形'],
      'Bridge': ['สะพาน', '桥'],
      'dicedash': ['เกมคำนวณ', '计算游戏'],
      'ARMS UP': ['ยกแขนขึ้น', '双臂上举'],
      'OVERHEAD REACH': ['เหยียดแขนเหนือศีรษะ', '双臂向上伸展'],
      'T-POSE': ['ท่าตัวที', 'T字姿势'],
      'CHEST OPENER': ['เปิดอกและหัวไหล่', '打开胸肩'],
      'RIGHT SHOULDER STRETCH': ['ยืดหัวไหล่ขวา', '右肩拉伸'],
      'LEFT SHOULDER STRETCH': ['ยืดหัวไหล่ซ้าย', '左肩拉伸'],
      'RIGHT QUAD STRETCH': ['ยืดต้นขาขวา', '右侧大腿拉伸'],
      'LEFT QUAD STRETCH': ['ยืดต้นขาซ้าย', '左侧大腿拉伸'],
      'NECK STRETCH RIGHT': ['ยืดคอด้านขวา', '颈部右侧拉伸'],
      'NECK STRETCH LEFT': ['ยืดคอด้านซ้าย', '颈部左侧拉伸'],
      'SIDE BEND RIGHT': ['เอียงตัวด้านขวา', '身体向右侧弯'],
      'SIDE BEND LEFT': ['เอียงตัวด้านซ้าย', '身体向左侧弯'],
      'RAISE BOTH ARMS STRAIGHT ABOVE YOUR HEAD': [
        'ยกแขนทั้งสองข้างขึ้นเหนือศีรษะ',
        '双臂伸直举过头顶',
      ],
      'STAND TALL AND REACH BOTH ARMS GENTLY ABOVE YOUR HEAD': [
        'ยืนตัวตรง แล้วค่อย ๆ เหยียดแขนทั้งสองข้างขึ้นเหนือศีรษะ',
        '站直身体，双臂轻轻向上伸过头顶',
      ],
      'KEEP YOUR ARMS UP AND BEND YOUR UPPER BODY GENTLY TO THE RIGHT': [
        'ยกแขนค้างไว้ แล้วค่อย ๆ เอียงลำตัวส่วนบนไปทางขวา',
        '保持双臂举起，上半身轻轻向右侧弯',
      ],
      'KEEP YOUR ARMS UP AND BEND YOUR UPPER BODY GENTLY TO THE LEFT': [
        'ยกแขนค้างไว้ แล้วค่อย ๆ เอียงลำตัวส่วนบนไปทางซ้าย',
        '保持双臂举起，上半身轻轻向左侧弯',
      ],
      'OPEN BOTH ARMS SIDEWAYS AND KEEP YOUR SHOULDERS RELAXED': [
        'กางแขนทั้งสองข้างออกด้านข้างและผ่อนคลายหัวไหล่',
        '双臂向两侧打开，保持肩膀放松',
      ],
      'BRING YOUR RIGHT ARM ACROSS YOUR CHEST AND KEEP IT STRAIGHT': [
        'เหยียดแขนขวาพาดผ่านหน้าอกและพยายามให้แขนตรง',
        '将右臂伸直横过胸前',
      ],
      'BRING YOUR LEFT ARM ACROSS YOUR CHEST AND KEEP IT STRAIGHT': [
        'เหยียดแขนซ้ายพาดผ่านหน้าอกและพยายามให้แขนตรง',
        '将左臂伸直横过胸前',
      ],
      'BEND YOUR RIGHT KNEE AND LIFT YOUR FOOT GENTLY BEHIND YOU': [
        'งอเข่าขวา แล้วยกเท้าขึ้นด้านหลังอย่างช้า ๆ',
        '弯曲右膝，将脚轻轻抬向身后',
      ],
      'BEND YOUR LEFT KNEE AND LIFT YOUR FOOT GENTLY BEHIND YOU': [
        'งอเข่าซ้าย แล้วยกเท้าขึ้นด้านหลังอย่างช้า ๆ',
        '弯曲左膝，将脚轻轻抬向身后',
      ],
      'OPEN BOTH ARMS SIDEWAYS LIKE A LETTER T': [
        'กางแขนทั้งสองข้างเป็นรูปตัวที',
        '双臂向两侧打开成T字',
      ],
      'TILT YOUR HEAD GENTLY TO THE RIGHT': [
        'ค่อย ๆ เอียงศีรษะไปทางขวา',
        '轻轻将头向右倾斜',
      ],
      'TILT YOUR HEAD GENTLY TO THE LEFT': [
        'ค่อย ๆ เอียงศีรษะไปทางซ้าย',
        '轻轻将头向左倾斜',
      ],
      'BEND YOUR UPPER BODY TO THE RIGHT': [
        'เอียงลำตัวส่วนบนไปทางขวา',
        '上半身向右侧弯',
      ],
      'BEND YOUR UPPER BODY TO THE LEFT': [
        'เอียงลำตัวส่วนบนไปทางซ้าย',
        '上半身向左侧弯',
      ],
    };
    final translated = names[englishName];
    if (translated == null) return englishName;
    return switch (AppLanguageController.current.value) {
      AppLanguage.thai => translated[0],
      AppLanguage.chinese => translated[1],
      AppLanguage.english => englishName,
    };
  }

  static String month(int month) {
    const english = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const thai = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    const chinese = [
      '一月',
      '二月',
      '三月',
      '四月',
      '五月',
      '六月',
      '七月',
      '八月',
      '九月',
      '十月',
      '十一月',
      '十二月',
    ];
    return switch (AppLanguageController.current.value) {
      AppLanguage.thai => thai[month - 1],
      AppLanguage.chinese => chinese[month - 1],
      AppLanguage.english => english[month - 1],
    };
  }

  static String weekday(int index) {
    const english = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const thai = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];
    const chinese = ['日', '一', '二', '三', '四', '五', '六'];
    return switch (AppLanguageController.current.value) {
      AppLanguage.thai => thai[index],
      AppLanguage.chinese => chinese[index],
      AppLanguage.english => english[index],
    };
  }
}
