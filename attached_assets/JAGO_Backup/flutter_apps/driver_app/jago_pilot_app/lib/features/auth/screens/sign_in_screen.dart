import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:jago_pilot_app/features/auth/screens/otp_log_in_screen.dart';
import 'package:jago_pilot_app/features/auth/screens/sign_up_screen.dart';
import 'package:jago_pilot_app/features/html/domain/html_enum_types.dart';
import 'package:jago_pilot_app/helper/display_helper.dart';
import 'package:jago_pilot_app/util/dimensions.dart';
import 'package:jago_pilot_app/util/images.dart';
import 'package:jago_pilot_app/util/styles.dart';
import 'package:jago_pilot_app/features/auth/controllers/auth_controller.dart';
import 'package:jago_pilot_app/features/dashboard/controllers/bottom_menu_controller.dart';
import 'package:jago_pilot_app/features/auth/screens/forgot_password_screen.dart';
import 'package:jago_pilot_app/features/html/screens/policy_viewer_screen.dart';
import 'package:jago_pilot_app/features/location/controllers/location_controller.dart';
import 'package:jago_pilot_app/features/profile/controllers/profile_controller.dart';
import 'package:jago_pilot_app/features/ride/controllers/ride_controller.dart';
import 'package:jago_pilot_app/features/splash/controllers/splash_controller.dart';
import 'package:jago_pilot_app/common_widgets/button_widget.dart';
import 'package:jago_pilot_app/common_widgets/text_field_widget.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {

  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  FocusNode phoneNode = FocusNode();
  FocusNode passwordNode = FocusNode();

  @override
  void initState() {
    if(Get.find<AuthController>().getUserNumber().isNotEmpty){
      phoneController.text =  Get.find<AuthController>().getUserNumber();
    }
    passwordController.text = Get.find<AuthController>().getUserPassword();
    if(passwordController.text != ''){
      Get.find<AuthController>().setRememberMe();
    }
    if(Get.find<AuthController>().getLoginCountryCode().isNotEmpty){
      Get.find<AuthController>().countryDialCode = Get.find<AuthController>().getLoginCountryCode();
    }else if(Get.find<SplashController>().config!.countryCode != null){
      Get.find<AuthController>().countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().config!.countryCode!).dialCode!;
    }
    super.initState();
  }

  @override
  void dispose() {
    passwordController.dispose();
    phoneController.dispose();
    phoneNode.dispose();
    passwordNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (res, val) async {
        Get.find<BottomMenuController>().exitApp();
        return;
      },
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: GetBuilder<AuthController>(builder: (authController){
            return GetBuilder<ProfileController>(builder: (profileController) {
              return GetBuilder<RideController>(builder: (rideController) {
                return GetBuilder<LocationController>(builder: (locationController) {
                  return Stack(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.35,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Image.asset(Images.logoWithName, height: 55,
                                color: Colors.white,
                                colorBlendMode: BlendMode.srcIn,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pilot Partner',
                                style: textMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 14,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),

                            Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(28),
                                  topRight: Radius.circular(28),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, -4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                                child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(
                                    'login'.tr,
                                    style: textBold.copyWith(
                                      fontSize: 24,
                                      color: Theme.of(context).textTheme.displayLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'log_in_message'.tr,
                                    style: textRegular.copyWith(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 28),

                                  TextFieldWidget(
                                    hintText: 'enter_your_phone'.tr,
                                    inputType: TextInputType.number,
                                    countryDialCode: authController.countryDialCode,
                                    controller: phoneController,
                                    focusNode: phoneNode,
                                    autoFocus: phoneController.text.isEmpty,
                                    onCountryChanged: (CountryCode countryCode){
                                      authController.countryDialCode = countryCode.dialCode!;
                                      authController.setCountryCode(countryCode.dialCode!);
                                      FocusScope.of(context).requestFocus(phoneNode);
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  TextFieldWidget(
                                    hintText: 'enter_your_password'.tr,
                                    inputType: TextInputType.text,
                                    prefixIcon: Images.lock,
                                    inputAction: TextInputAction.done,
                                    focusNode: passwordNode,
                                    isPassword: true,
                                    controller: passwordController,
                                  ),

                                  Row(children: [
                                    InkWell(
                                      onTap: () => authController.toggleRememberMe(),
                                      child: Row(children: [
                                        SizedBox(width: 20.0, child: Checkbox(
                                          checkColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          activeColor: Theme.of(context).primaryColor,
                                          value: authController.isActiveRememberMe,
                                          side: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.4)),
                                          onChanged: (bool? isChecked) => authController.toggleRememberMe(),
                                        )),
                                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                        Text(
                                          'remember'.tr,
                                          style: textRegular.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ),
                                      ]),
                                    ),

                                    const Spacer(),

                                    TextButton(
                                      onPressed: () => Get.to(()=>const ForgotPasswordScreen()),
                                      child: Text(
                                        'forgot_password'.tr,
                                        style: textMedium.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 8),

                                  (authController.isLoading || authController.updateFcm ||
                                      profileController.isLoading || rideController.isLoading ||
                                      locationController.lastLocationLoading) ?
                                  Center(child: SpinKitCircle(color: Theme.of(context).primaryColor, size: 40.0)) :
                                  ButtonWidget(
                                    buttonText: 'login'.tr,
                                    onPressed: (){
                                      String phone = phoneController.text;
                                      String password = passwordController.text;
                                      if(phone.isEmpty){
                                        showCustomSnackBar('phone_is_required'.tr);
                                        FocusScope.of(context).requestFocus(phoneNode);
                                      }else if(!GetUtils.isPhoneNumber(authController.countryDialCode + phone)){
                                        showCustomSnackBar('phone_number_is_not_valid'.tr);
                                        FocusScope.of(context).requestFocus(phoneNode);
                                      }else if(password.isEmpty){
                                        showCustomSnackBar('password_is_required'.tr);
                                        FocusScope.of(context).requestFocus(passwordNode);
                                      }else if(password.length<8){
                                        showCustomSnackBar('minimum_password_length_is_8'.tr);
                                        FocusScope.of(context).requestFocus(passwordNode);
                                      }else{
                                        authController.login(authController.countryDialCode,phone, password);
                                      }
                                    }, radius: 14,
                                  ),

                                    if(Get.find<SplashController>().config?.isOtpLoginEnable ?? false)...[
                                      Center(child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 12),
                                        child: Row(children: [
                                          Expanded(child: Divider(color: Theme.of(context).hintColor.withValues(alpha: 0.2))),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: Text('or'.tr, style: textRegular.copyWith(color: Theme.of(context).hintColor)),
                                          ),
                                          Expanded(child: Divider(color: Theme.of(context).hintColor.withValues(alpha: 0.2))),
                                        ]),
                                      )),

                                      ButtonWidget(
                                        showBorder: true,
                                        borderWidth: 1.5,
                                        transparent: true,
                                        buttonText: 'otp_login'.tr,
                                        onPressed: () => Get.to(() => const OtpLoginScreen(fromSignIn: true)),
                                        radius: 14,
                                      )
                                    ],
                                  const SizedBox(height: 24),

                                  (Get.find<SplashController>().config!.selfRegistration != null &&
                                      Get.find<SplashController>().config!.selfRegistration!) ?
                                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text(
                                      '${'do_not_have_an_account'.tr} ',
                                      style: textRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),

                                    TextButton(
                                      onPressed: () =>  Get.to(()=> const SignUpScreen()),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero, minimumSize: const Size(50,30),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'sign_up'.tr,
                                        style: textSemiBold.copyWith(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ]) :
                                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text("${'to_create_account'.tr} ",
                                      style: textRegular.copyWith(color: Theme.of(context).hintColor),
                                    ),

                                    InkWell(
                                      onTap: ()=>
                                          Get.find<SplashController>().sendMailOrCall(
                                            "tel:${Get.find<SplashController>().config?.businessContactPhone}",
                                            false,
                                          ),
                                      child: Text(
                                        "${'contact_support'.tr} ",
                                        style: textMedium.copyWith(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 8),

                                  Center(
                                    child: InkWell(
                                      onTap: ()=> Get.to(()=> const PolicyViewerScreen(htmlType: HtmlType.termsAndConditions)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                                        child: Text(
                                          "terms_and_condition".tr,
                                          style: textRegular.copyWith(
                                            color: Theme.of(context).hintColor,
                                            fontSize: 12,
                                            decoration: TextDecoration.underline,
                                            decorationColor: Theme.of(context).hintColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                });
              });
            });
          }),
        ),
      ),
    );
  }
}
