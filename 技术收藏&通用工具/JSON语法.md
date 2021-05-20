# 什么是 JSON ？

+ JSON 指的是 JavaScript 对象表示法（**J**ava**S**cript **O**bject **N**otation）
+ JSON 是轻量级的==文本数据交换格式==
+ JSON 独立于语言：JSON 使用 Javascript语法来描述数据对象，但是 JSON 仍然独立于语言和平台。JSON 解析器和 JSON 库支持许多不同的编程语言。 目前非常多的动态（PHP，JSP，.NET）编程语言都支持JSON。
+ JSON 具有自我描述性，更易理解



# JSON语法

JSON 语法是 JavaScript 对象表示语法的子集。

+ 数据在**名称/值**对中
+ 数据由逗号分隔
+ 大括号 **{}** 保存对象
+ 中括号 **[]** 保存数组，数组可以包含多个对象

JSON 值可以是：

+ 数字（整数或浮点数）
+ 字符串（在双引号中）
+ 逻辑值（true 或 false）
+ 数组（在中括号中）
+ 对象（在大括号中）
+ null

JSON实例：

```json
{
    "sites": [
        { "name":"菜鸟教程" , "url":"www.runoob.com" }, 
        { "name":"google" , "url":"www.google.com" }, 
        { "name":"微博" , "url":"www.weibo.com" }
    ]
}
```



# JSON对象

```JSON
{ "name":"runoob", "alexa":10000, "site":null }
```

JSON 对象使用在大括号(`{}`)中书写。对象可以包含多个 **key/value（键/值）**对。

key 必须是字符串，value 可以是合法的 JSON 数据类型（字符串, 数字, 对象, 数组, 布尔值或 null）。

key 和 value 中使用冒号(`:`)分割。每个 key/value 对使用逗号(`,`)分割。

## 嵌套 JSON 对象

JSON 对象中可以包含另外一个 JSON 对象：

```JSON
{
    "name":"runoob",
    "alexa":10000,
    "sites": {
        "site1":"www.runoob.com",
        "site2":"m.runoob.com",
        "site3":"c.runoob.com"
    }
}
```



# JSON 数组

## JSON 对象中的数组

对象属性的值可以是一个数组：

```c++
{
"name":"网站",
"num":3,
"sites":[ "Google", "Runoob", "Taobao" ]
}
```

## 嵌套 JSON 对象中的数组

JSON 对象中数组可以包含另外一个数组，或者另外一个 JSON 对象：

```c++
{
    "name":"网站",
    "num":3,
    "sites": [
        { "name":"Google", "info":[ "Android", "Google 搜索", "Google 翻译" ] },
        { "name":"Runoob", "info":[ "菜鸟教程", "菜鸟工具", "菜鸟微信" ] },
        { "name":"Taobao", "info":[ "淘宝", "网购" ] }
    ]
}
```



# JSON.parse()

JSON 通常用于与服务端交换数据。

在接收服务器数据时一般是字符串。

我们可以使用 JSON.parse() 方法将数据转换为 JavaScript 对象。

```javascript
JSON.parse(text[, reviver])
```

**参数说明：**

+ **text：**必需， 一个有效的 JSON 字符串。
+ **reviver：** 可选，一个转换结果的函数， 将为对象的每个成员调用此函数。

