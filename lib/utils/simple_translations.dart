// Add these to your SimpleTranslations class

class SimpleTranslations {
  static final Map<String, Map<String, String>> _translations = {
    'en': {
      // Existing keys...
      'loginTitle': 'Login',
      'phone': 'Phone Number',
      'password': 'Password',
      'rememberMe': 'Remember Me',
      'login': 'Login',
      'login_failed': 'Login failed',

      // New keys for the updated LoginPage
      'app_name': 'POS Driver',
      'phone_hint': 'Enter your phone number',
      'password_hint': 'Enter your password',
      'phone_required': 'Phone number is required',
      'phone_invalid': 'Please enter a valid phone number',
      'password_required': 'Password is required',
      'password_too_short': 'Password must be at least 4 characters',
      'invalid_credentials': 'Invalid phone number or password',
      'server_error': 'Server error. Please try again later.',
      'connection_timeout': 'Connection timeout. Please check your internet.',
      'invalid_response': 'Invalid response from server',
      'no_internet_connection':
          'No internet connection. Please check your network.',
      'server_unavailable': 'Server is currently unavailable',
      'network_error': 'Network error occurred',
    },
    'la': {
      // Existing keys...
      'loginTitle': 'ເຂົ້າສູ່ລະບົບ',
      'phone': 'ເບີໂທລະສັບ',
      'password': 'ລະຫັດຜ່ານ',
      'rememberMe': 'ຈື່ຂ້ອຍ',
      'login': 'ເຂົ້າສູ່ລະບົບ',
      'login_failed': 'ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ',

      // New keys for the updated LoginPage
      'app_name': 'ພິໄອເອສ ລົດແທັກຊີ',
      'phone_hint': 'ປ້ອນເບີໂທລະສັບຂອງທ່ານ',
      'password_hint': 'ປ້ອນລະຫັດຜ່ານຂອງທ່ານ',
      'phone_required': 'ຕ້ອງປ້ອນເບີໂທລະສັບ',
      'phone_invalid': 'ກະລຸນາປ້ອນເບີໂທລະສັບທີ່ຖືກຕ້ອງ',
      'password_required': 'ຕ້ອງປ້ອນລະຫັດຜ່ານ',
      'password_too_short': 'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 4 ຕົວອັກສອນ',
      'invalid_credentials': 'ເບີໂທລະສັບ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ',
      'server_error': 'ເກີດຂໍ້ຜິດພາດຂອງເຊີເວີ. ກະລຸນາລອງໃໝ່ໃນພາຍຫຼັງ.',
      'connection_timeout': 'ການເຊື່ອມຕໍ່ຫມົດເວລາ. ກະລຸນາກວດສອບອິນເຕີເນັດ.',
      'invalid_response': 'ການຕອບກັບຈາກເຊີເວີບໍ່ຖືກຕ້ອງ',
      'no_internet_connection':
          'ບໍ່ມີການເຊື່ອມຕໍ່ອິນເຕີເນັດ. ກະລຸນາກວດສອບເຄືອຂ່າຍ.',
      'server_unavailable': 'ເຊີເວີບໍ່ສາມາດໃຊ້ງານໄດ້ໃນຂະນະນີ້',
      'network_error': 'ເກີດຂໍ້ຜິດພາດຂອງເຄືອຂ່າຍ',
    },
  };

  static String get(String langCode, String key) {
    return _translations[langCode]?[key] ?? key;
  }
}
