import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/features/auth/screens/otp_log_in_screen.dart';
import 'package:jago_user_app/features/auth/screens/forgot_password_screen.dart';
import 'package:jago_user_app/features/settings/domain/html_enum_types.dart';
import 'package:jago_user_app/helper/display_helper.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/util/images.dart';
import 'package:jago_user_app/util/styles.dart';
import 'package:jago_user_app/features/auth/controllers/auth_controller.dart';
import 'package:jago_user_app/features/auth/screens/sign_up_screen.dart';
import 'package:jago_user_app/features/settings/screens/policy_screen.dart';
import 'package:jago_user_app/features/splash/controllers/config_controller.dart';
import 'package:jago_user_app/common_widgets/button_widget.dart';
import 'package:jago_user_app/common_widgets/custom_text_field.dart';
import 'package:url_launcher/url_launcher.dart';

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
    super.initState();

    if(Get.find<AuthController>().getUserNumber(false).isNotEmpty) {
      phoneController.text =  Get.find<AuthController>().getUserNumber(false);
    }
    passwordController.text = Get.find<AuthController>().getUserPassword(false);

    if(passwordController.text.isNotEmpty) {
      Get.find<AuthController>().setRememberMe();
    }

    if(Get.find<AuthController>().getLoginCountryCode(false).isNotEmpty) {
      Get.find<AuthController>().countryDialCode = Get.find<AuthController>().getLoginCountryCode(false);
    }else if(Get.find<ConfigController>().config!.countryCode != null){
      Get.find<AuthController>().countryDialCode = CountryCode.fromCountryCode(Get.find<ConfigController>().config!.countryCode!).dialCode!;
    }
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
    return SafeArea(child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GetBuilder<AuthController>(builder: (authController) {
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
                    Image.asset(Images.logoWithName, height: 60, width: 180,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Move Smarter.',
                      style: textMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        letterSpacing: 1.2,
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
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          'ready_to_ride'.tr,
                          style: textBold.copyWith(
                            fontSize: 24,
                            color: Theme.of(context).textTheme.titleMedium?.color,
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

                        CustomTextField(
                          isCodePicker: true,
                          hintText: 'phone'.tr,
                          inputType: TextInputType.phone,
                          countryDialCode: authController.countryDialCode,
                          controller: phoneController,
                          focusNode: phoneNode,
                          nextFocus: passwordNode,
                          inputAction: TextInputAction.next,
                          onCountryChanged: (CountryCode countryCode) {
                            authController.countryDialCode = countryCode.dialCode!;
                            authController.setCountryCode(countryCode.dialCode!);
                            FocusScope.of(context).requestFocus(phoneNode);
                          },
                          autoFocus: phoneController.text.isEmpty,
                        ),
                        const SizedBox(height: 16),

                        CustomTextField(
                          hintText: 'enter_password'.tr,
                          inputType: TextInputType.text,
                          prefixIcon: Images.lock,
                          inputAction: TextInputAction.done,
                          isPassword: true,
                          controller: passwordController,
                          focusNode: passwordNode,
                        ),

                        Row(children: [
                          Padding(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                            child: InkWell(
                              onTap: () => authController.toggleRememberMe(),
                              child: Row(children: [
                                SizedBox(width: 20.0, child: Checkbox(
                                  checkColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  activeColor: Theme.of(context).primaryColor,
                                  value: authController.isActiveRememberMe,
                                  side: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
                                  onChanged: (bool? isChecked) => authController.toggleRememberMe(),
                                )),
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                Text(
                                  'remember_me'.tr,
                                  style: textRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ]),
                            ),
                          ),

                          const Spacer(),

                          TextButton(
                            onPressed: () {
                              Get.to(() => const ForgotPasswordScreen());
                            },
                            child: Text('forgot_password'.tr, style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).primaryColor,
                            )),
                          ),
                        ]),
                        const SizedBox(height: 8),

                        authController.isLoading ?
                        Center(child: SpinKitCircle(color: Theme.of(context).primaryColor, size: 40.0)) :
                        ButtonWidget(
                          buttonText: 'log_in'.tr,
                          onPressed: () {
                            String phone = phoneController.text.trim();
                            String password = passwordController.text.trim();

                            if(phone.isEmpty){
                              showCustomSnackBar('phone_number_is_required'.tr);
                              FocusScope.of(context).requestFocus(phoneNode);
                            }else if(!GetUtils.isPhoneNumber(authController.countryDialCode + phone)) {
                              showCustomSnackBar('phone_number_is_not_valid'.tr);
                              FocusScope.of(context).requestFocus(phoneNode);
                            }else if(password.isEmpty) {
                              showCustomSnackBar('password_is_required'.tr);
                              FocusScope.of(context).requestFocus(passwordNode);
                            }else if(password.length < 8) {
                              showCustomSnackBar('minimum_password_length_is_8'.tr);
                            }else {
                              authController.login(authController.countryDialCode, phone, password);
                            }
                          },
                          radius: 14,
                        ),

                        if(Get.find<ConfigController>().config?.isOtpLoginEnable ?? false)...[
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

                        if(!(Get.find<ConfigController>().config?.externalSystem ?? false))...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${'do_not_have_an_account'.tr} ',
                                style: textRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),

                              TextButton(
                                onPressed: () {
                                  Get.to(() => const SignUpScreen());
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50,30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text('sign_up'.tr, style: textSemiBold.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: Dimensions.fontSizeSmall,
                                )),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],

                        Center(
                          child: InkWell(
                            onTap: ()=> Get.to(() => PolicyScreen(htmlType: HtmlType.termsAndConditions, image: Get.find<ConfigController>().config?.termsAndConditions?.image??'',)),
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
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: GetBuilder<AuthController>(builder: (authController){
        return ((Get.find<ConfigController>().config?.externalSystem ?? false) && authController.showNavigationBar) ?
        Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
              color: Theme.of(Get.context!).textTheme.titleMedium!.color!
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                child: Icon(Icons.info,size: 20,color: Theme.of(context).cardColor),
              ),

              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('this_is_not_an_independent_app'.tr,style: textRegular.copyWith(color: Theme.of(context).cardColor)),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  RichText(text: TextSpan(
                      text: 'this_app_is_connected_with_6ammart'.tr,
                      style: textRegular.copyWith(color: Theme.of(context).cardColor.withValues(alpha:0.7),fontSize: Dimensions.fontSizeExtraSmall),
                      children: [
                        TextSpan(
                            text: ' ${'click_here_to_sigh_up'.tr}',
                            style: textRegular.copyWith(color: Theme.of(context).colorScheme.surfaceContainer,fontSize: Dimensions.fontSizeExtraSmall,decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()..onTap = () async{
                              navigateToMart('sixammart://open?country_code=&phone=signUp&password=}');
                            }
                        ),
                        TextSpan(
                            text: '  ${'or'.tr}  ',
                            style: textRegular.copyWith(color: Theme.of(context).cardColor,fontSize: Dimensions.fontSizeExtraSmall)
                        ),
                        TextSpan(
                            text: 'download_mart'.tr,
                            style: textRegular.copyWith(color: Theme.of(context).colorScheme.surfaceContainer,fontSize: Dimensions.fontSizeExtraSmall,decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()..onTap = () async{
                              if(GetPlatform.isAndroid && Get.find<ConfigController>().config?.martPlayStoreUrl != null){
                                navigateToMart(Get.find<ConfigController>().config!.martPlayStoreUrl!);
                              }else if(GetPlatform.isIOS && Get.find<ConfigController>().config?.martAppStoreUrl != null){
                                navigateToMart(Get.find<ConfigController>().config!.martAppStoreUrl!);
                              }else{
                                showCustomSnackBar('contact_with_support'.tr);
                              }
                            }
                        )
                      ]
                  ))
                ])),

                InkWell(
                  onTap: ()=> authController.toggleNavigationBar(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                    child: Icon(Icons.clear,color: Theme.of(context).cardColor),
                  ),
                )
              ])),
            ]),
          ]),
        ) :
        const SizedBox();
      }),
    ));
  }

  void navigateToMart(String url) async{
    if(GetPlatform.isAndroid){
      try{
        await launchUrl(Uri.parse(url));
      }catch(exception){
        navigateToStores(url);
      }
    }else if(GetPlatform.isIOS){
      if(await launchUrl(Uri.parse(url))){}else{
        navigateToStores(url);
      }
    }
  }
  void navigateToStores(String url) async{
    if(GetPlatform.isAndroid && Get.find<ConfigController>().config?.martPlayStoreUrl != null){
      await launchUrl(Uri.parse(Get.find<ConfigController>().config!.martPlayStoreUrl!));
    }else if(GetPlatform.isIOS && Get.find<ConfigController>().config?.martAppStoreUrl != null){
      await launchUrl(Uri.parse(Get.find<ConfigController>().config!.martAppStoreUrl!));
    }else{
      showCustomSnackBar('contact_with_support'.tr);
    }
  }
}
