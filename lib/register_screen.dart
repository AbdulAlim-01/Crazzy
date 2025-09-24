import 'package:crazzy_ai_tool/home_screen.dart';
import 'package:crazzy_ai_tool/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCountry = 'United States';
  String _selectedCountryCode = '+1';
  String? _errorMessage;
  bool _isLoading = false;

  final List<Map<String, String>> _countries = [
    {"name": "Afghanistan", "code": "+93"},
    {"name": "Albania", "code": "+355"},
    {"name": "Algeria", "code": "+213"},
    {"name": "American Samoa", "code": "+1-684"},
    {"name": "Andorra", "code": "+376"},
    {"name": "Angola", "code": "+244"},
    {"name": "Anguilla", "code": "+1-264"},
    {"name": "Antarctica", "code": "+672"},
    {"name": "Antigua and Barbuda", "code": "+1-268"},
    {"name": "Argentina", "code": "+54"},
    {"name": "Armenia", "code": "+374"},
    {"name": "Aruba", "code": "+297"},
    {"name": "Australia", "code": "+61"},
    {"name": "Austria", "code": "+43"},
    {"name": "Azerbaijan", "code": "+994"},
    {"name": "Bahamas", "code": "+1-242"},
    {"name": "Bahrain", "code": "+973"},
    {"name": "Bangladesh", "code": "+880"},
    {"name": "Barbados", "code": "+1-246"},
    {"name": "Belarus", "code": "+375"},
    {"name": "Belgium", "code": "+32"},
    {"name": "Belize", "code": "+501"},
    {"name": "Benin", "code": "+229"},
    {"name": "Bermuda", "code": "+1-441"},
    {"name": "Bhutan", "code": "+975"},
    {"name": "Bolivia", "code": "+591"},
    {"name": "Bosnia and Herzegovina", "code": "+387"},
    {"name": "Botswana", "code": "+267"},
    {"name": "Brazil", "code": "+55"},
    {"name": "British Indian Ocean Territory", "code": "+246"},
    {"name": "British Virgin Islands", "code": "+1-284"},
    {"name": "Brunei", "code": "+673"},
    {"name": "Bulgaria", "code": "+359"},
    {"name": "Burkina Faso", "code": "+226"},
    {"name": "Burundi", "code": "+257"},
    {"name": "Cambodia", "code": "+855"},
    {"name": "Cameroon", "code": "+237"},
    {"name": "Canada", "code": "+1"},
    {"name": "Cape Verde", "code": "+238"},
    {"name": "Cayman Islands", "code": "+1-345"},
    {"name": "Central African Republic", "code": "+236"},
    {"name": "Chad", "code": "+235"},
    {"name": "Chile", "code": "+56"},
    {"name": "China", "code": "+86"},
    {"name": "Christmas Island", "code": "+61"},
    {"name": "Cocos Islands", "code": "+61"},
    {"name": "Colombia", "code": "+57"},
    {"name": "Comoros", "code": "+269"},
    {"name": "Congo", "code": "+242"},
    {"name": "Cook Islands", "code": "+682"},
    {"name": "Costa Rica", "code": "+506"},
    {"name": "Croatia", "code": "+385"},
    {"name": "Cuba", "code": "+53"},
    {"name": "Curacao", "code": "+599"},
    {"name": "Cyprus", "code": "+357"},
    {"name": "Czech Republic", "code": "+420"},
    {"name": "Democratic Republic of the Congo", "code": "+243"},
    {"name": "Denmark", "code": "+45"},
    {"name": "Djibouti", "code": "+253"},
    {"name": "Dominica", "code": "+1-767"},
    {"name": "Dominican Republic", "code": "+1-809, +1-829, +1-849"},
    {"name": "East Timor", "code": "+670"},
    {"name": "Ecuador", "code": "+593"},
    {"name": "Egypt", "code": "+20"},
    {"name": "El Salvador", "code": "+503"},
    {"name": "Equatorial Guinea", "code": "+240"},
    {"name": "Eritrea", "code": "+291"},
    {"name": "Estonia", "code": "+372"},
    {"name": "Ethiopia", "code": "+251"},
    {"name": "Falkland Islands", "code": "+500"},
    {"name": "Faroe Islands", "code": "+298"},
    {"name": "Fiji", "code": "+679"},
    {"name": "Finland", "code": "+358"},
    {"name": "France", "code": "+33"},
    {"name": "French Polynesia", "code": "+689"},
    {"name": "Gabon", "code": "+241"},
    {"name": "Gambia", "code": "+220"},
    {"name": "Georgia", "code": "+995"},
    {"name": "Germany", "code": "+49"},
    {"name": "Ghana", "code": "+233"},
    {"name": "Gibraltar", "code": "+350"},
    {"name": "Greece", "code": "+30"},
    {"name": "Greenland", "code": "+299"},
    {"name": "Grenada", "code": "+1-473"},
    {"name": "Guam", "code": "+1-671"},
    {"name": "Guatemala", "code": "+502"},
    {"name": "Guernsey", "code": "+44-1481"},
    {"name": "Guinea", "code": "+224"},
    {"name": "Guinea-Bissau", "code": "+245"},
    {"name": "Guyana", "code": "+592"},
    {"name": "Haiti", "code": "+509"},
    {"name": "Honduras", "code": "+504"},
    {"name": "Hong Kong", "code": "+852"},
    {"name": "Hungary", "code": "+36"},
    {"name": "Iceland", "code": "+354"},
    {"name": "India", "code": "+91"},
    {"name": "Indonesia", "code": "+62"},
    {"name": "Iran", "code": "+98"},
    {"name": "Iraq", "code": "+964"},
    {"name": "Ireland", "code": "+353"},
    {"name": "Isle of Man", "code": "+44-1624"},
    {"name": "Israel", "code": "+972"},
    {"name": "Italy", "code": "+39"},
    {"name": "Ivory Coast", "code": "+225"},
    {"name": "Jamaica", "code": "+1-876"},
    {"name": "Japan", "code": "+81"},
    {"name": "Jersey", "code": "+44-1534"},
    {"name": "Jordan", "code": "+962"},
    {"name": "Kazakhstan", "code": "+7"},
    {"name": "Kenya", "code": "+254"},
    {"name": "Kiribati", "code": "+686"},
    {"name": "Kosovo", "code": "+383"},
    {"name": "Kuwait", "code": "+965"},
    {"name": "Kyrgyzstan", "code": "+996"},
    {"name": "Laos", "code": "+856"},
    {"name": "Latvia", "code": "+371"},
    {"name": "Lebanon", "code": "+961"},
    {"name": "Lesotho", "code": "+266"},
    {"name": "Liberia", "code": "+231"},
    {"name": "Libya", "code": "+218"},
    {"name": "Liechtenstein", "code": "+423"},
    {"name": "Lithuania", "code": "+370"},
    {"name": "Luxembourg", "code": "+352"},
    {"name": "Macau", "code": "+853"},
    {"name": "Macedonia", "code": "+389"},
    {"name": "Madagascar", "code": "+261"},
    {"name": "Malawi", "code": "+265"},
    {"name": "Malaysia", "code": "+60"},
    {"name": "Maldives", "code": "+960"},
    {"name": "Mali", "code": "+223"},
    {"name": "Malta", "code": "+356"},
    {"name": "Marshall Islands", "code": "+692"},
    {"name": "Mauritania", "code": "+222"},
    {"name": "Mauritius", "code": "+230"},
    {"name": "Mayotte", "code": "+262"},
    {"name": "Mexico", "code": "+52"},
    {"name": "Micronesia", "code": "+691"},
    {"name": "Moldova", "code": "+373"},
    {"name": "Monaco", "code": "+377"},
    {"name": "Mongolia", "code": "+976"},
    {"name": "Montenegro", "code": "+382"},
    {"name": "Montserrat", "code": "+1-664"},
    {"name": "Morocco", "code": "+212"},
    {"name": "Mozambique", "code": "+258"},
    {"name": "Myanmar", "code": "+95"},
    {"name": "Namibia", "code": "+264"},
    {"name": "Nauru", "code": "+674"},
    {"name": "Nepal", "code": "+977"},
    {"name": "Netherlands", "code": "+31"},
    {"name": "Netherlands Antilles", "code": "+599"},
    {"name": "New Caledonia", "code": "+687"},
    {"name": "New Zealand", "code": "+64"},
    {"name": "Nicaragua", "code": "+505"},
    {"name": "Niger", "code": "+227"},
    {"name": "Nigeria", "code": "+234"},
    {"name": "Niue", "code": "+683"},
    {"name": "North Korea", "code": "+850"},
    {"name": "Northern Mariana Islands", "code": "+1-670"},
    {"name": "Norway", "code": "+47"},
    {"name": "Oman", "code": "+968"},
    {"name": "Pakistan", "code": "+92"},
    {"name": "Palau", "code": "+680"},
    {"name": "Palestine", "code": "+970"},
    {"name": "Panama", "code": "+507"},
    {"name": "Papua New Guinea", "code": "+675"},
    {"name": "Paraguay", "code": "+595"},
    {"name": "Peru", "code": "+51"},
    {"name": "Philippines", "code": "+63"},
    {"name": "Pitcairn", "code": "+64"},
    {"name": "Poland", "code": "+48"},
    {"name": "Portugal", "code": "+351"},
    {"name": "Puerto Rico", "code": "+1-787, +1-939"},
    {"name": "Qatar", "code": "+974"},
    {"name": "Reunion", "code": "+262"},
    {"name": "Romania", "code": "+40"},
    {"name": "Russia", "code": "+7"},
    {"name": "Rwanda", "code": "+250"},
    {"name": "Saint Barthelemy", "code": "+590"},
    {"name": "Saint Helena", "code": "+290"},
    {"name": "Saint Kitts and Nevis", "code": "+1-869"},
    {"name": "Saint Lucia", "code": "+1-758"},
    {"name": "Saint Martin", "code": "+590"},
    {"name": "Saint Pierre and Miquelon", "code": "+508"},
    {"name": "Saint Vincent and the Grenadines", "code": "+1-784"},
    {"name": "Samoa", "code": "+685"},
    {"name": "San Marino", "code": "+378"},
    {"name": "Sao Tome and Principe", "code": "+239"},
    {"name": "Saudi Arabia", "code": "+966"},
    {"name": "Senegal", "code": "+221"},
    {"name": "Serbia", "code": "+381"},
    {"name": "Seychelles", "code": "+248"},
    {"name": "Sierra Leone", "code": "+232"},
    {"name": "Singapore", "code": "+65"},
    {"name": "Sint Maarten", "code": "+1-721"},
    {"name": "Slovakia", "code": "+421"},
    {"name": "Slovenia", "code": "+386"},
    {"name": "Solomon Islands", "code": "+677"},
    {"name": "Somalia", "code": "+252"},
    {"name": "South Africa", "code": "+27"},
    {"name": "South Korea", "code": "+82"},
    {"name": "South Sudan", "code": "+211"},
    {"name": "Spain", "code": "+34"},
    {"name": "Sri Lanka", "code": "+94"},
    {"name": "Sudan", "code": "+249"},
    {"name": "Suriname", "code": "+597"},
    {"name": "Svalbard and Jan Mayen", "code": "+47"},
    {"name": "Swaziland", "code": "+268"},
    {"name": "Sweden", "code": "+46"},
    {"name": "Switzerland", "code": "+41"},
    {"name": "Syria", "code": "+963"},
    {"name": "Taiwan", "code": "+886"},
    {"name": "Tajikistan", "code": "+992"},
    {"name": "Tanzania", "code": "+255"},
    {"name": "Thailand", "code": "+66"},
    {"name": "Togo", "code": "+228"},
    {"name": "Tokelau", "code": "+690"},
    {"name": "Tonga", "code": "+676"},
    {"name": "Trinidad and Tobago", "code": "+1-868"},
    {"name": "Tunisia", "code": "+216"},
    {"name": "Turkey", "code": "+90"},
    {"name": "Turkmenistan", "code": "+993"},
    {"name": "Turks and Caicos Islands", "code": "+1-649"},
    {"name": "Tuvalu", "code": "+688"},
    {"name": "U.S. Virgin Islands", "code": "+1-340"},
    {"name": "Uganda", "code": "+256"},
    {"name": "Ukraine", "code": "+380"},
    {"name": "United Arab Emirates", "code": "+971"},
    {"name": "United Kingdom", "code": "+44"},
    {"name": "United States", "code": "+1"},
    {"name": "Uruguay", "code": "+598"},
    {"name": "Uzbekistan", "code": "+998"},
    {"name": "Vanuatu", "code": "+678"},
    {"name": "Vatican City", "code": "+379"},
    {"name": "Venezuela", "code": "+58"},
    {"name": "Vietnam", "code": "+84"},
    {"name": "Wallis and Futuna", "code": "+681"},
    {"name": "Western Sahara", "code": "+212"},
    {"name": "Yemen", "code": "+967"},
    {"name": "Zambia", "code": "+260"},
    {"name": "Zimbabwe", "code": "+263"}
  ];

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your full name';
        _isLoading = false;
      });
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
        _isLoading = false;
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a password';
        _isLoading = false;
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }

    try {
      // First, sign up the user
      print("Start sign up");
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print("complete sign up");
      if (response.user != null) {
        // Wait a bit to ensure user is fully created
        await Future.delayed(const Duration(milliseconds: 500));
        print("Start saving value in profile");
        // Create user profile - Fixed syntax error by adding comma after 'type': 'open'
        await Supabase.instance.client.from('profiles').insert({
          'id': response.user!.id,
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'plan': 'Free', // Default plan
          'credits': 15,
          'user_id':
              '${_nameController.text.trim()}_${response.user!.id.substring(0, 5)}',
          'country': _selectedCountry,
          'type': 'open', // Fixed: Added missing comma
          'phone_number': _selectedCountryCode + _phoneController.text.trim(),
        });

        print("complete saving value in profile");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        print(e.message);
      });
    } on PostgrestException catch (e) {
      setState(() {
        _errorMessage = 'Database error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2A2A),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Join Crazzy',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.person, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF424242),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.email, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF424242),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF424242),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF424242),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              // Country Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(
                  labelText: 'Country',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.flag, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF424242),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                dropdownColor: const Color(0xFF424242),
                style: const TextStyle(color: Colors.white),
                items: _countries
                    .map((country) => DropdownMenuItem<String>(
                          value: country['name'],
                          child: Text(
                            '${country['name']} (${country['code']})',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value!;
                    _selectedCountryCode = _countries
                        .firstWhere((c) => c['name'] == value)['code']!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Phone Number Field
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    child: Text(
                      _selectedCountryCode,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  filled: true,
                  fillColor: const Color(0xFF424242),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF0E639C)),
                    )
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E639C),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
