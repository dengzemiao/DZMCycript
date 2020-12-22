(function(exports) {

  // 错误提示
	var invalidParamStr = 'Invalid parameter';
	var missingParamStr = 'Missing parameter';

	// app id
	DZMAppId = [NSBundle mainBundle].bundleIdentifier;

	// mainBundlePath
	DZMAppPath = [NSBundle mainBundle].bundlePath;

	// document path
	DZMDocPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];

	// caches path
	DZMCachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]; 

	// 加载系统动态库
	DZMLoadFramework = function(name) {
		var head = "/System/Library/";
		var foot = "Frameworks/" + name + ".framework";
		var bundle = [NSBundle bundleWithPath:head + foot] || [NSBundle bundleWithPath:head + "Private" + foot];
  		[bundle load];
  		return bundle;
	};

	// keyWindow
	DZMKeyWindow = function() {
		return UIApp.keyWindow;
	};

	// 根控制器
	DZMRootVc =  function() {
		return UIApp.keyWindow.rootViewController;
	};

	// 找到显示在最前面的控制器
	var _DZMFrontVc = function(vc) {
		if (vc.presentedViewController) {
        	return _DZMFrontVc(vc.presentedViewController);
	    }else if ([vc isKindOfClass:[UITabBarController class]]) {
	        return _DZMFrontVc(vc.selectedViewController);
	    } else if ([vc isKindOfClass:[UINavigationController class]]) {
	        return _DZMFrontVc(vc.visibleViewController);
	    } else {
	    	var count = vc.childViewControllers.count;
    		for (var i = count - 1; i >= 0; i--) {
    			var childVc = vc.childViewControllers[i];
    			if (childVc && childVc.view.window) {
    				vc = _DZMFrontVc(childVc);
    				break;
    			}
    		}
	        return vc;
    	}
	};

	DZMFrontVc = function() {
		return _DZMFrontVc(UIApp.keyWindow.rootViewController);
	};

	// 递归打印 UIViewController view 的层级结构
	DZMVcSubviews = function(vc) { 
		if (![vc isKindOfClass:[UIViewController class]]) throw new Error(invalidParamStr);
		return vc.view.recursiveDescription().toString(); 
	};

	// 递归打印最上层 UIViewController view 的层级结构
	DZMFrontVcSubViews = function() {
		return DZMVcSubviews(_DZMFrontVc(UIApp.keyWindow.rootViewController));
	};

	// 获取按钮绑定的所有 TouchUpInside 事件的方法名
	DZMBtnTouchUpEvent = function(btn) { 
		var events = [];
		var allTargets = btn.allTargets().allObjects()
		var count = allTargets.count;
    	for (var i = count - 1; i >= 0; i--) { 
    		if (btn != allTargets[i]) {
    			var e = [btn actionsForTarget:allTargets[i] forControlEvent:UIControlEventTouchUpInside];
    			events.push(e);
    		}
    	}
	   return events;
	};

	// CG函数
	DZMPointMake = function(x, y) { 
		return {0 : x, 1 : y}; 
	};

	DZMSizeMake = function(w, h) { 
		return {0 : w, 1 : h}; 
	};

	DZMRectMake = function(x, y, w, h) { 
		return {0 : DZMPointMake(x, y), 1 : DZMSizeMake(w, h)}; 
	};

	// 递归打印 Controller 的层级结构
	DZMChildVcs = function(vc) {
		if (![vc isKindOfClass:[UIViewController class]]) throw new Error(invalidParamStr);
		return [vc _printHierarchy].toString();
	};


	// 递归打印 View 的层级结构
	DZMSubviews = function(view) { 
		if (![view isKindOfClass:[UIView class]]) throw new Error(invalidParamStr);
		return view.recursiveDescription().toString(); 
	};

	// 判断是否为字符串 "str" @"str"
	DZMIsString = function(str) {
		return typeof str == 'string' || str instanceof String;
	};

	// 判断是否为数组 []、@[]
	DZMIsArray = function(arr) {
		return arr instanceof Array;
	};

	// 判断是否为数字 666 @666
	DZMIsNumber = function(num) {
		return typeof num == 'number' || num instanceof Number;
	};

	var _DZMClass = function(className) {
		if (!className) throw new Error(missingParamStr);
		if (DZMIsString(className)) {
			return NSClassFromString(className);
		} 
		if (!className) throw new Error(invalidParamStr);
		// 对象或者类
		return className.class();
	};

	// 打印所有的子类
	DZMSublasses = function(className, reg) {
		className = _DZMClass(className);

		return [c for each (c in ObjectiveC.classes) 
		if (c != className 
			&& class_getSuperclass(c) 
			&& [c isSubclassOfClass:className] 
			&& (!reg || reg.test(c)))
			];
	};

	// 打印所有的方法
	var _DZMGetMethods = function(className, reg, clazz) {
		className = _DZMClass(className);

		var count = new new Type('I');
		var classObj = clazz ? className.constructor : className;
		var methodList = class_copyMethodList(classObj, count);
		var methodsArray = [];
		var methodNamesArray = [];
		for(var i = 0; i < *count; i++) {
			var method = methodList[i];
			var selector = method_getName(method);
			var name = sel_getName(selector);
			if (reg && !reg.test(name)) continue;
			methodsArray.push({
				selector : selector, 
				type : method_getTypeEncoding(method)
			});
			methodNamesArray.push(name);
		}
		free(methodList);
		return [methodsArray, methodNamesArray];
	};

	var _DZMMethods = function(className, reg, clazz) {
		return _DZMGetMethods(className, reg, clazz)[0];
	};

	// 打印所有的方法名字
	var _DZMMethodNames = function(className, reg, clazz) {
		return _DZMGetMethods(className, reg, clazz)[1];
	};

	// 打印所有的对象方法
	DZMInstanceMethods = function(className, reg) {
		return _DZMMethods(className, reg);
	};

	// 打印所有的对象方法名字
	DZMInstanceMethodNames = function(className, reg) {
		return _DZMMethodNames(className, reg);
	};

	// 打印所有的类方法
	DZMClassMethods = function(className, reg) {
		return _DZMMethods(className, reg, true);
	};

	// 打印所有的类方法名字
	DZMClassMethodNames = function(className, reg) {
		return _DZMMethodNames(className, reg, true);
	};

	// 打印所有的成员变量
	DZMIvars = function(obj, reg){ 
		if (!obj) throw new Error(missingParamStr);
		var x = {}; 
		for(var i in *obj) { 
			try { 
				var value = (*obj)[i];
				if (reg && !reg.test(i) && !reg.test(value)) continue;
				x[i] = value; 
			} catch(e){} 
		} 
		return x; 
	};

	// 打印所有的成员变量名字
	DZMIvarNames = function(obj, reg) {
		if (!obj) throw new Error(missingParamStr);
		var array = [];
		for(var name in *obj) { 
			if (reg && !reg.test(name)) continue;
			array.push(name);
		}
		return array;
  };
  
})(exports);