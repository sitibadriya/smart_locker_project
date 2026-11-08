import 'package:flutter/widgets.dart';
import '../constants/app_constants.dart';
class ResponsiveHelper { static bool isMobile(BuildContext c)=>MediaQuery.sizeOf(c).width<AppConstants.webBreakpoint; static bool isTablet(BuildContext c)=>MediaQuery.sizeOf(c).width>=600&&MediaQuery.sizeOf(c).width<AppConstants.webBreakpoint; }
