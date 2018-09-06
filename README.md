# __block

## 一. 改变变量的值的一般方式

看下面代码,其打印值为 age = 10;

```objc
typedef void(^test1Block)(void);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        int age = 10;
        
        test1Block block = ^{
            NSLog(@"age = %d",age);
        };
        block();
        
    }
    return 0;
}
```

此时如果想改变 `age` 的值.如下写法是否正确?

```objc
typedef void(^test1Block)(void);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        int age = 10;
        
        test1Block block = ^{
            
            // 注意: 这么写编译报错!
            age = 20;
            
            NSLog(@"age = %d",age);
        };
        block();
        
    }
    return 0;
}
```

观测上述代码的`c++` 代码结构可知:

- 在`__main_block_func_0` 这个函数中,其输出 age 是拿到的 block 内部的 age.
- 在`main`内部直接改其局部变量,不能修改之前捕获的值的.

```c++
typedef void(*test1Block)(void);


struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  int age;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int _age, int flags=0) : age(_age) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};

static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  int age = __cself->age; // bound by copy

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_w8_wnywnfxn7zldh13vnt816cmm0000gn_T_main_3afe36_mi_0,age);
        }

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};
int main(int argc, const char * argv[]) {
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 

        int age = 10;

        test1Block block = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, age));
        ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);

    }
    return 0;
}
```

**改变 age 值的正确做法:**

- 将 age 改为 static 修饰
    - static 修饰后,地址传递.可以修改. 
- 将 age 改为 全局变量.
    - 全局变量, block 不会捕获,输出时直接拿. 

## 二. __block 的方式改变变量的值

上面两种改变变量值的做法,有一个弊端.就是将age 改为 static 修饰或全局变量后,其在内存中不会销毁.那么和我们想要的局部变量使用完就让其销毁有点出入.

所以这里我们使用`__block`来解决这个问题.

```objc
// 打印结果: age = 20;
typedef void(^test1Block)(void);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        __block int age = 10;
        
        test1Block block = ^{
            
            age = 20;
            
            NSLog(@"age = %d",age);
        };
        block();
        
    }
    return 0;
}
```

## 三. __block 的原理及它如何改变变量的值的?

### 3.1 __block 修饰符能修饰谁?

- `__block` 可以修饰`auto`变量.
- `__block` `不能` 修饰`全局变量` 和`静态变量(static)` 

### 3.2 __block 是如何修改 auto 变量的值的?

将上述修改 `auto` 变量的值的 `oc` 代码,编译成 `c++` 代码,看 `__block` 如何改变变量的值的.

编译后的 `c++` 代码如下,观测下其代码结构:

```c++
#pragma clang assume_nonnull end

typedef void(*test1Block)(void);

struct __Block_byref_age_0 {
  void *__isa;
__Block_byref_age_0 *__forwarding;
 int __flags;
 int __size;
 int age;
};

struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __Block_byref_age_0 *age; // by ref
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, __Block_byref_age_0 *_age, int flags=0) : age(_age->__forwarding) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  __Block_byref_age_0 *age = __cself->age; // bound by ref


            (age->__forwarding->age) = 20;

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_w8_wnywnfxn7zldh13vnt816cmm0000gn_T_main_d5b4ce_mi_0,(age->__forwarding->age));
        }
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {_Block_object_assign((void*)&dst->age, (void*)src->age, 8/*BLOCK_FIELD_IS_BYREF*/);}

static void __main_block_dispose_0(struct __main_block_impl_0*src) {_Block_object_dispose((void*)src->age, 8/*BLOCK_FIELD_IS_BYREF*/);}

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
  void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
  void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0), __main_block_copy_0, __main_block_dispose_0};
int main(int argc, const char * argv[]) {
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 

        __attribute__((__blocks__(byref))) __Block_byref_age_0 age = {(void*)0,(__Block_byref_age_0 *)&age, 0, sizeof(__Block_byref_age_0), 10};

        test1Block block = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, (__Block_byref_age_0 *)&age, 570425344));
        ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);

    }
    return 0;
}
```

#### 3.2.1 `__block int age = 10` 代码对比

- `__block int age = 10;` 这句代码编译成`c++`后,其实现为:

```c++
// 原 OC 代码实现
__block int age = 10;

// c++ 代码实现
__attribute__((__blocks__(byref))) __Block_byref_age_0 age = {(void*)0,(__Block_byref_age_0 *)&age, 0, sizeof(__Block_byref_age_0), 10};

// c++ 代码简化后:
__Block_byref_age_0 age = {
            (void*)0,
            (__Block_byref_age_0 *)&age,
            0,
            sizeof(__Block_byref_age_0),
            10
        };
```

- 由上可以看出,`int age = 10`加上 `__block` 修饰后,会变为 一个`__Block_byref_age_0` 结构体.

#### 3.2.2 `__Block_byref_age_0` 结构体

```c++
struct __Block_byref_age_0 {
  void *__isa;
__Block_byref_age_0 *__forwarding;  ///< 就是自己这个结构体的地址, __forwarding 这个指针指向结构体自己
 int __flags;
 int __size;    ///< 结构体的大小
 int age;
};
```

`__block int age = 10`,它的底层编译后,下面的值一一对应的赋值给结构体的成员.

```c++
__attribute__((__blocks__(byref))) __Block_byref_age_0 age = {
(void*)0,
// 将自己这个结构体的地址传给自己的第2个成员 __forwarding
(__Block_byref_age_0 *)&age, 
0, 
sizeof(__Block_byref_age_0), 
10
};
```

#### 3.2.3 定义 block 部分

oc 定义 block 的代码和 c++ 定义 block 的代码对比来看:

```c++
// OC 定义 block 的代码
test1Block block = ^{
            age = 20;
            NSLog(@"age = %d",age);
        };
        
        
// c++ 定义 block 的代码
test1Block block = (
(void (*)())&__main_block_impl_0((void *)__main_block_func_0, 
&__main_block_desc_0_DATA, 
(__Block_byref_age_0 *)&age, 
570425344));
```

- 第一个成员 `(void (*)())&__main_block_impl_0((void *)__main_block_func_0`

```c++
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __Block_byref_age_0 *age; // by ref
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, __Block_byref_age_0 *_age, int flags=0) : age(_age->__forwarding) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  __Block_byref_age_0 *age = __cself->age; // bound by ref


            (age->__forwarding->age) = 20;

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_w8_wnywnfxn7zldh13vnt816cmm0000gn_T_main_d5b4ce_mi_0,(age->__forwarding->age));
        }
```

- 第2个成员 `&__main_block_desc_0_DATA`

```c++
static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
  void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
  void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0), __main_block_copy_0, __main_block_dispose_0};
```

- 第3个成员 `(__Block_byref_age_0 *)&age,`

将`__block int age = 10` 编译后的结构体的地址传给 `struct __main_block_impl_0` 这个结构体的第3个成员`__Block_byref_age_0 *age; `


- 第4个成员暂时不看.

- 所以说. 
    - `struct __main_block_impl_0`  这个结构体内部有个指针 `__Block_byref_age_0 *age` 指向 `struct __Block_byref_age_0 ` 这个结构体.
    - 而 `struct __Block_byref_age_0 ` 这个结构体内部有成员 `int age;`
    - 所以最后拿到这个成员 age

#### 3.2.4 修改值

- block 通过其内部成员 `__Block_byref_age_0 *age; ` 这个指针,找到 `struct __Block_byref_age_0` 这个结构体.
- 然后通过这个结构体,拿到其内部第2个成员`__forwarding` 这个指针,但是这个指针指向的就是它自己这个结构体
- 通过`__forwarding` 拿到其内部的成员 `int age`
- 然后将 age 赋值为 20
- 从而改变 age 的值.

```c++
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  __Block_byref_age_0 *age = __cself->age; // bound by ref


            (age->__forwarding->age) = 20;

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_w8_wnywnfxn7zldh13vnt816cmm0000gn_T_main_d5b4ce_mi_0,(age->__forwarding->age));
        }
```

## 四 __block 的内存管理

### 4.1 __block 修饰 auto 变量时

- 当 block 在栈上时, 不会对 `__block` 变量产生强引用
- 当 block 被 copy 到堆上时
    - 会调用 block 内部的 `__main_block_copy_0` 函数
    - `__main_block_copy_0` 函数内部会调用 `__Block_object_assign` 函数
    - `__Block_object_assign` 函数会对 `__block` 变量形成强引用

    ```c++
    static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {
    _Block_object_assign((void*)&dst->age, (void*)src->age, 8/*BLOCK_FIELD_IS_BYREF*/);
    }
    ``` 
    
- 当 block 从堆中移除的时候
    - 会调用 block 内部的 `__main_block_dispose_0` 函数 
    - `__main_block_dispose_0` 函数内部会调用 `_Block_object_dispose` 函数
    - `_Block_object_dispose` 函数会自动释放引用的 `__block`变量

    ```c++
        static void __main_block_dispose_0(struct __main_block_impl_0*src) {_Block_object_dispose((void*)src->age, 8/*BLOCK_FIELD_IS_BYREF*/);
    }
    ```


### 4.2 __block 修饰对象类型变量时

- 当 __block 变量在栈上的时候,不会对指向的对象产生强引用.
- 当 __block 变量被 copy 到堆上的时候
    - 会调用 __block 变量内部的 copy 函数
    - copy 函数内部会调用 `__Block_object_assign`函数
    - `__Block_object_assign` 函数会根据所指向对象的修饰符(`__strong`, `__weak`, `__unsafe_unretained`) 做出相应的操作.形成强引用还是弱引用(retain 操作,仅在 ARC 下, MRC 下即使用`__block`修饰也不会 retain 操作) 

- `__block` 变量从堆上移除时
    - 会调用 `__block`变量内部的`dispose` 函数
    - `dispose` 函数内部会调用 `__Block_object_dispose` 函数
    - `__Block_object_dispose` 函数会自动释放指向的对象(release 操作) 




