# **技术架构文档: 拣配流程追溯与验证程序**

## **1\. 项目结构与代码组织**

采用 **“功能优先 (Feature-First)”** 的项目结构，以实现高可维护性和扩展性。

picking\_verification\_app/  
├── lib/  
│   ├── main.dart                 \# 应用主入口  
│   │  
│   ├── core/                     \# 核心/共享模块  
│   │   ├── api/                  \# API客户端、拦截器  
│   │   ├── config/               \# 路由配置 (GoRouter)  
│   │   ├── theme/                \# 应用主题 (蓝色主题)  
│   │   └── widgets/              \# 全局通用组件  
│   │  
│   ├── features/                 \# 核心功能模块  
│   │   ├── auth/                 \# 1\. 用户认证功能  
│   │   ├── task\_board/           \# 2\. 任务看板功能  
│   │   ├── picking\_verification/ \# 3\. 合箱校验功能  
│   │   ├── platform\_receiving/   \# 4\. 平台收料功能  
│   │   └── line\_delivery/        \# 5\. 产线送料功能  
│   │  
│   └── models/                   \# 全局数据模型  
│  
├── assets/  
│   └── images/  
│       └── company\_logo.png      \# 公司Logo  
│  
└── test/                         \# 测试代码

## **2\. 组件化标准**

* **设计哲学:** 优先使用无状态组件 (StatelessWidget)，仅在必要时使用有状态组件。复杂界面需拆分为多个职责单一的小组件。  
* **标准组件模板:** 所有新组件均需遵循标准模板以保证代码风格统一。

## **3\. 状态管理策略**

* **选型决策:** 采用 **BLoC (Business Logic Component)** 模式，使用 flutter\_bloc 库。  
* **理由:** 强制将业务逻辑与UI分离，使代码可预测、可测试、可扩展。  
* **核心流程:** **UI 发出 Event \-\> BLoC 处理 Event \-\> BLoC 发出新 State \-\> UI 根据新 State 重绘**。

## **4\. API 集成策略**

* **HTTP 客户端:** 使用功能强大的 dio 包进行网络请求。  
* **数据层模式:** 采用**仓储模式 (Repository Pattern)**，将数据来源的复杂性与业务逻辑 (BLoC) 隔离。  
* **实现:**  
  * 创建一个全局唯一的 dio 实例，配置基础 URL 和认证拦截器（自动附加 Token）。  
  * 每个功能模块创建自己的仓储类（e.g., AuthRepository），封装该模块的所有 API 调用。

## **5\. 导航与路由**

* **路由库:** 使用官方推荐的 go\_router 包。  
* **理由:** 提供基于 URL 的路由、简单的导航 API 和强大的重定向功能，非常适合实现登录保护。  
* **实现:**  
  * 配置全局 GoRouter 实例，定义所有页面路径（如 /login, /tasks, /picking-verification/:orderId）。  
  * 实现 redirect 逻辑作为路由守卫，检查用户登录状态，自动将未登录用户重定向到 /login 页面。

## **6\. 技术栈摘要**

* **框架:** Flutter  
* **状态管理:** BLoC (flutter\_bloc)  
* **网络请求:** dio  
* **路由:** go\_router  
* **安全存储 (Token):** flutter\_secure\_storage