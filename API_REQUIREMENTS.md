# 做伴（BitePal）后端接口需求文档

> **文档用途**: 本文档用于前后端开发对接，包含完整的接口定义、数据模型、请求响应格式等。

## 📋 目录

- [环境配置](#-环境配置)
- [字段类型说明](#-字段类型说明)
- [重要说明](#-重要说明)
- [一、应用功能总结](#一应用功能总结)
- [二、数据模型设计](#二数据模型设计)
- [三、接口详细设计](#三接口详细设计)
- [四、通用响应格式](#四通用响应格式)
- [五、接口调用流程](#五接口调用流程)
- [六、接口规范说明](#六接口规范说明)
- [七、数据同步说明](#七数据同步说明)
- [八、安全要求](#八安全要求)
- [九、性能要求](#九性能要求)
- [十、扩展性考虑](#十扩展性考虑)
- [十一、测试要求](#十一测试要求)
- [附录：数据字典](#附录数据字典)

---

## 🔧 环境配置

### 基础 URL 配置

**开发环境**: `http://localhost:8080/api`  
**测试环境**: `https://api-test.bitepal.com/api`  
**生产环境**: `https://api.bitepal.com/api`

> ⚠️ **注意**: 前后端对接时请确认使用正确的环境 URL

### 请求头配置

所有接口请求需要包含以下请求头：

```
Content-Type: application/json
Accept: application/json
```

需要认证的接口还需包含：

```
Authorization: Bearer {token}
```

### 接口调用示例

#### cURL 示例

```bash
# 登录接口示例
curl -X POST "https://api.bitepal.com/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'

# 获取菜谱列表示例（需要认证）
curl -X GET "https://api.bitepal.com/api/recipes/my?page=1&pageSize=20" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

#### JavaScript/Fetch 示例

```javascript
// 登录接口
const response = await fetch("https://api.bitepal.com/api/auth/login", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    username: "testuser",
    password: "password123",
  }),
});

const data = await response.json();

// 获取菜谱列表（需要认证）
const recipesResponse = await fetch(
  "https://api.bitepal.com/api/recipes/my?page=1&pageSize=20",
  {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
  }
);

const recipesData = await recipesResponse.json();
```

#### Dart/Flutter 示例

```dart
// 登录接口
final response = await http.post(
  Uri.parse('https://api.bitepal.com/api/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'username': 'testuser',
    'password': 'password123',
  }),
);

final data = jsonDecode(response.body);

// 获取菜谱列表（需要认证）
final recipesResponse = await http.get(
  Uri.parse('https://api.bitepal.com/api/recipes/my?page=1&pageSize=20'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
);

final recipesData = jsonDecode(recipesResponse.body);
```

---

## 📝 字段类型说明

文档中使用的字段类型约定：

- **字符串 (String)**: 文本类型，如 `"菜谱名称"`、`"15分钟"`
- **整数 (Integer)**: 整型数字，如 `1`、`100`
- **浮点数 (Float/Double)**: 小数，如 `4.5`、`96.7`
- **布尔值 (Boolean)**: `true` 或 `false`
- **数组 (Array)**: `["标签1", "标签2"]`
- **对象 (Object)**: `{"key": "value"}`
- **可选字段**: 标注为 `（可选）` 的字段可以不传，后端会使用默认值或忽略
- **必填字段**: 未标注 `（可选）` 的字段为必填

---

## ⚠️ 重要说明

### 接口状态

- ✅ **已实现**: 接口已完成开发，可以直接调用
- 🚧 **开发中**: 接口正在开发，暂不可用
- 📋 **计划中**: 接口已规划，尚未开始开发

> 当前文档中的所有接口均为 **计划中** 状态，实际开发时请与后端确认接口状态。

### 版本管理

- 当前文档版本: **v1.0**
- API 版本: **v1**
- 接口路径前缀: `/api/v1/` (可选，根据后端实现)

### 数据格式约定

1. **ID 类型**: 统一使用字符串类型（String），如 `"123"` 而非数字 `123`
2. **时间戳**: 使用 ISO 8601 格式，如 `"2024-01-01T00:00:00Z"`
3. **日期**: 使用 `YYYY-MM-DD` 格式，如 `"2024-01-01"`
4. **价格**: 使用浮点数，保留两位小数，如 `4.50`

---

## 一、应用功能总结

### 1.1 核心功能模块

**做伴**是一款家庭做饭助手应用，主要包含以下功能模块：

1. **首页模块**

   - 今日菜单推荐
   - 即将过期食材提醒
   - 随机推荐菜品（"随便吃点"功能）

2. **菜谱管理模块**

   - 我的菜谱：用户自定义菜谱管理
   - 网络菜谱：公共菜谱库浏览
   - 菜谱搜索与筛选（口味、难度、菜系）
   - 菜谱收藏功能

3. **家庭点餐模块**

   - 菜品浏览与选择
   - 点餐清单管理
   - 多维度筛选（口味、食材状态、餐点类型、菜系）
   - 确认点餐提交

4. **食材库存管理模块**

   - 食材分类管理（常温、冷藏、冷冻）
   - 食材过期提醒
   - 食材库存统计

5. **购物清单模块**

   - 购物清单创建与管理
   - 购物项编辑（名称、数量、价格）
   - 购物清单分享
   - 价格统计

6. **菜谱详情模块**

   - 菜谱详细信息展示
   - 菜谱编辑（名称、时间、难度、标签、食材、步骤）
   - 加入今日菜单/我的菜单
   - 菜谱分享

7. **个人中心模块**
   - 用户信息管理
   - 统计数据展示（本月做饭次数、食材浪费减少率）
   - 购物订单历史
   - 家庭成员偏好设置
   - App 设置

---

## 二、数据模型设计

### 2.1 用户模型 (User)

```json
{
  "id": "用户ID",
  "username": "用户名",
  "nickname": "昵称",
  "avatar": "头像URL",
  "userId": "用户唯一标识（如：COOK_2024_0321）",
  "createdAt": "创建时间",
  "updatedAt": "更新时间"
}
```

### 2.2 菜谱模型 (Recipe)

```json
{
  "id": "菜谱ID",
  "name": "菜谱名称",
  "image": "图片URL（可选）",
  "time": "制作时间（如：15分钟）",
  "difficulty": "难度（简单/中等/困难）",
  "tags": ["标签数组"],
  "tagColors": ["标签颜色数组"],
  "favorite": "是否收藏",
  "categories": ["分类数组（如：家常菜、酸甜）"],
  "ingredients": [
    {
      "name": "食材名称",
      "amount": "用量",
      "available": "是否可用"
    }
  ],
  "steps": ["制作步骤数组"],
  "userId": "创建用户ID（我的菜谱）",
  "isPublic": "是否公开（网络菜谱）",
  "createdAt": "创建时间",
  "updatedAt": "更新时间"
}
```

### 2.3 食材库存模型 (IngredientItem)

```json
{
  "id": "食材ID",
  "name": "食材名称",
  "amount": "数量（如：2个）",
  "category": "存储分类（room/fridge/freezer）",
  "icon": "图标（emoji）",
  "expiryDate": "过期日期（ISO 8601格式）",
  "expiryDays": "距离过期的天数",
  "expiryText": "过期文本（如：今天、明天、3天后）",
  "urgent": "是否紧急（当天过期）",
  "userId": "用户ID",
  "createdAt": "创建时间",
  "updatedAt": "更新时间"
}
```

### 2.4 购物清单模型 (ShoppingList)

```json
{
  "id": "清单ID",
  "name": "清单名称（可选）",
  "items": [
    {
      "id": "购物项ID",
      "name": "商品名称",
      "amount": "数量（如：2个）",
      "price": "价格",
      "checked": "是否已购买"
    }
  ],
  "totalPrice": "总价",
  "userId": "用户ID",
  "createdAt": "创建时间",
  "updatedAt": "更新时间",
  "completedAt": "完成时间（可选）"
}
```

### 2.5 今日菜单模型 (TodayMenu)

```json
{
  "id": "菜单ID",
  "date": "日期（YYYY-MM-DD）",
  "recipes": [
    {
      "recipeId": "菜谱ID",
      "recipeName": "菜谱名称",
      "mealType": "餐点类型（早餐/午餐/晚餐/夜宵）"
    }
  ],
  "userId": "用户ID",
  "createdAt": "创建时间",
  "updatedAt": "更新时间"
}
```

### 2.6 点餐清单模型 (MealOrder)

```json
{
  "id": "点餐ID",
  "recipes": [
    {
      "recipeId": "菜谱ID",
      "recipeName": "菜谱名称"
    }
  ],
  "status": "状态（pending/confirmed/completed）",
  "userId": "用户ID",
  "createdAt": "创建时间",
  "updatedAt": "更新时间"
}
```

### 2.7 用户统计数据模型 (UserStats)

```json
{
  "userId": "用户ID",
  "monthlyCookingCount": "本月做饭次数",
  "wasteReductionRate": "食材浪费减少率（百分比）",
  "totalRecipes": "总菜谱数",
  "favoriteRecipes": "收藏菜谱数",
  "updatedAt": "更新时间"
}
```

---

## 三、接口详细设计

### 3.1 用户认证接口

#### 3.1.1 用户登录

- **接口路径**: `POST /api/auth/login`
- **请求参数**:

```json
{
  "username": "用户名或手机号",
  "password": "密码"
}
```

- **响应数据**:

```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "token": "JWT Token",
    "user": {
      "id": "用户ID",
      "username": "用户名",
      "nickname": "昵称",
      "avatar": "头像URL",
      "userId": "用户唯一标识"
    }
  }
}
```

#### 3.1.2 用户注册

- **接口路径**: `POST /api/auth/register`
- **请求参数**:

```json
{
  "username": "用户名",
  "password": "密码",
  "nickname": "昵称（可选）",
  "phone": "手机号（可选）"
}
```

- **响应数据**: 同登录接口

#### 3.1.3 获取用户信息

- **接口路径**: `GET /api/user/info`
- **请求头**: `Authorization: Bearer {token}`
- **响应数据**:

```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "id": "用户ID",
    "username": "用户名",
    "nickname": "昵称",
    "avatar": "头像URL",
    "userId": "用户唯一标识"
  }
}
```

#### 3.1.4 更新用户信息

- **接口路径**: `PUT /api/user/info`
- **请求头**: `Authorization: Bearer {token}`
- **请求参数**:

```json
{
  "nickname": "新昵称（可选）",
  "avatar": "新头像URL（可选）"
}
```

- **响应数据**: 同获取用户信息接口

---

### 3.2 菜谱管理接口

#### 3.2.1 获取我的菜谱列表

- **接口路径**: `GET /api/recipes/my`
- **请求头**: `Authorization: Bearer {token}`
- **查询参数**:
  - `page`: 页码（默认 1）
  - `pageSize`: 每页数量（默认 20）
  - `keyword`: 搜索关键词（可选）
  - `tastes`: 口味筛选（可选，多个用逗号分隔，如：酸甜,麻辣）
  - `difficulty`: 难度筛选（可选，如：简单,中等,困难）
  - `cuisines`: 菜系筛选（可选，如：川菜,粤菜）
  - `favorite`: 是否只显示收藏（可选，true/false）
- **响应数据**:

```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "list": [
      {
        "id": "菜谱ID",
        "name": "菜谱名称",
        "image": "图片URL",
        "time": "15分钟",
        "difficulty": "简单",
        "tags": ["常做"],
        "tagColors": ["bg-blue-500"],
        "favorite": true,
        "categories": ["家常菜", "酸甜"]
      }
    ],
    "total": 100,
    "page": 1,
    "pageSize": 20
  }
}
```

#### 3.2.2 获取网络菜谱列表

- **接口路径**: `GET /api/recipes/public`
- **请求头**: `Authorization: Bearer {token}`
- **查询参数**: 同我的菜谱列表
- **响应数据**: 同我的菜谱列表

#### 3.2.3 获取菜谱详情

- **接口路径**: `GET /api/recipes/{recipeId}`
- **请求头**: `Authorization: Bearer {token}`
- **响应数据**:

```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "id": "菜谱ID",
    "name": "菜谱名称",
    "image": "图片URL",
    "time": "45分钟",
    "difficulty": "中等",
    "tags": ["清淡", "老人适合", "营养丰富"],
    "tagColors": ["bg-blue-500"],
    "favorite": false,
    "categories": ["川菜", "咸鲜"],
    "ingredients": [
      {
        "name": "西红柿",
        "amount": "2个",
        "available": true
      }
    ],
    "steps": [
      "将西红柿洗净，切成均匀的橘瓣块。",
      "鸡蛋打入碗中，加入少许盐，搅拌均匀备用。"
    ],
    "userId": "创建用户ID",
    "isPublic": false,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

#### 3.2.4 创建菜谱

- **接口路径**: `POST /api/recipes`
- **请求头**: `Authorization: Bearer {token}`
- **请求参数**:

```json
{
  "name": "菜谱名称",
  "image": "图片URL（可选）",
  "time": "15分钟",
  "difficulty": "简单",
  "tags": ["常做"],
  "tagColors": ["bg-blue-500"],
  "categories": ["家常菜", "酸甜"],
  "ingredients": [
    {
      "name": "西红柿",
      "amount": "2个"
    }
  ],
  "steps": ["步骤1", "步骤2"],
  "isPublic": false
}
```

- **响应数据**: 同获取菜谱详情

#### 3.2.5 更新菜谱

- **接口路径**: `PUT /api/recipes/{recipeId}`
- **请求头**: `Authorization: Bearer {token}`
- **请求参数**: 同创建菜谱（所有字段可选）
- **响应数据**: 同获取菜谱详情

#### 3.2.6 删除菜谱

- **接口路径**: `DELETE /api/recipes/{recipeId}`
- **请求头**: `Authorization: Bearer {token}`
- **响应数据**:

```json
{
  "code": 200,
  "message": "删除成功",
  "data": null
}
```

#### 3.2.7 收藏/取消收藏菜谱

- **接口路径**: `POST /api/recipes/{recipeId}/favorite`
- **请求头**: `Authorization: Bearer {token}`
- **请求参数**:

```json
{
  "favorite": true
}
```

- **响应数据**:

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "favorite": true
  }
}
```

#### 3.2.8 加入我的菜单（从网络菜谱）

- **接口路径**: `POST /api/recipes/{recipeId}/add-to-my`
- **请求头**: `Authorization: Bearer {token}`
- **响应数据**: 同获取菜谱详情

---

### 3.3 今日菜单接口

#### 3.3.1 获取今日菜单

- **接口路径**: `GET /api/today-menu`
- **请求头**: `Authorization: Bearer {token}`
- **查询参数**:
  - `date`: 日期（可选，格式：YYYY-MM-DD，默认今天）
- **响应数据**:

```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "id": "菜单ID",
    "date": "2024-01-01",
    "recipes": [
      {
        "recipeId": "菜谱ID",
        "recipeName": "番茄炒蛋",
        "mealType": "午餐"
      }
    ]
  }
}
```

#### 3.3.2 添加菜谱到今日菜单

- **接口路径**: `POST /api/today-menu/recipes`
- **请求头**: `Authorization: Bearer {token}`
- **请求参数**:

```json
{
  "recipeId": "菜谱ID",
  "mealType": "午餐（可选，默认：晚餐）",
  "date": "日期（可选，格式：YYYY-MM-DD，默认今天）"
}
```

- **响应数据**: 同获取今日菜单

#### 3.3.3 从今日菜单移除菜谱

- **接口路径**: `DELETE /api/today-menu/recipes/{recipeId}`
- **请求头**: `Authorization: Bearer {token}`
- **查询参数**:
  - `date`: 日期（可选，默认今天）
- **响应数据**:

```json
{
  "code": 200,
  "message": "移除成功",
  "data": null
}
```

---

### 3.4 家庭点餐接口

#### 3.4.1 获取点餐菜品列表

- **接口路径**: `GET /api/meals/recipes`
- **请求头**: `Authorization: Bearer {token}`
- **查询参数**:
  - `page`: 页码（默认 1）
  - `pageSize`: 每页数量（默认 20）
  - `keyword`: 搜索关键词（可选）
  - `tastes`: 口味筛选（可选，如：酸,甜,苦,麻,辣）
  - `status`: 食材状态筛选（可选，如：食材充足,需要补充）
  - `mealTypes`: 餐点类型筛选（可选，如：早餐,午餐,晚餐,夜宵）
  - `cuisines`: 菜系筛选（可选，如：川菜,粤菜,鲁菜,西餐）
- **响应数据**: 同菜谱列表接口

#### 3.4.2 创建点餐清单

- **接口路径**: `POST /api/meals/orders`
- **请求头**: `Authorization: Bearer {token}`
- **请求参数**:

```json
{
  "recipes": [
    {
      "recipeId": "菜谱ID",
      "recipeName": "菜谱名称"
    }
  ]
}
```

- **响应数据**:

```json
{
  "code": 200,
  "message": "创建成功",
  "data": {
    "id": "点餐ID",
    "recipes": [
      {
        "recipeId": "菜谱ID",
        "recipeName": "菜谱名称"
      }
    ],
    "status": "pending",
    "createdAt": "2024-01-01T00:00:00Z"
  }
}
```

#### 3.4.3 确认点餐

- **接口路径**: `POST /api/meals/orders/{orderId}/confirm`
- **请求头**: `Authorization: Bearer {token}`
- **响应数据**:

```json
{
  "code": 200,
  "message": "确认成功",
  "data": {
    "id": "点餐ID",
    "status": "confirmed",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

#### 3.4.4 获取点餐历史

- **接口路径**: `GET /api/meals/orders`
- **请求头**: `Authorization: Bearer {token}`
- **查询参数**:
  - `page`: 页码（默认 1）
  - `pageSize`: 每页数量（默认 20）
  - `status`: 状态筛选（可选，如：pending,confirmed,completed）
- **响应数据**:

```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "list": [
      {
        "id": "点餐ID",
        "recipes": [
          {
            "recipeId": "菜谱ID",
            "recipeName": "菜谱名称"
          }
        ],
        "status": "confirmed",
        "createdAt": "2024-01-01T00:00:00Z"
      }
    ],
    "total": 50,
    "page": 1,
    "pageSize": 20
  }
}
```

---

### 3.5 食材库存管理接口

#### 3.5.1 获取食材列表

- **接口路径**: `GET /api/ingredients`
- **请求头**: `Authorization: Bearer {token}`
- **查询参数**:
  - `category`: 分类筛选（可选，如：room,fridge,freezer）
  - `urgent`: 是否只显示紧急（可选，true/false）
  - `expiringDays`: 过期天数筛选（可选，如：0 表示今天过期，1 表示明天过期）
- **响应数据**:

```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "list": [
      {
        "id": "食材ID",
        "name": "生菜",
        "amount": "1颗",
        "category": "fridge",
        "icon": "🥬",
        "expiryDate": "2024-01-01",
        "expiryDays": 0,
        "expiryText": "今天",
        "urgent": true
      }
    ],
    "total": 20
  }
}
```

#### 3.5.2 获取即将过期食材

- **接口路径**: `GET /api/ingredients/expiring`
- **请求头**: `Authorization: Bearer {token}`
- **查询参数**:
  - `days`: 天数（可选，默认 3，表示 3 天内过期）
- **响应数据**: 同获取食材列表

#### 3.5.3 添加食材

- **接口路径**: `POST /api/ingredients`
- **请求头**: `Authorization: Bearer {token}`
- **请求参数**:

```json
{
  "name": "生菜",
  "amount": "1颗",
  "category": "fridge",
  "icon": "🥬",
  "expiryDate": "2024-01-05"
}
```

- **响应数据**: 同获取食材详情

#### 3.5.4 更新食材

- **接口路径**: `PUT /api/ingredients/{ingredientId}`
- **请求头**: `Authorization: Bearer {token}`
- **请求参数**: 同添加食材（所有字段可选）
- **响应数据**: 同获取食材详情

#### 3.5.5 删除食材

- **接口路径**: `DELETE /api/ingredients/{ingredientId}`
- **请求头**: `Authorization: Bearer {token}`
- **响应数据**:

```json
{
  "code": 200,
  "message": "删除成功",
  "data": null
}
```

#### 3.5.6 获取食材详情

- **接口路径**: `GET /api/ingredients/{ingredientId}`
- **请求头**: `Authorization: Bearer {token}`
- **响应数据**:

```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "id": "食材ID",
    "name": "生菜",
    "amount": "1颗",
    "category": "fridge",
    "icon": "🥬",
    "expiryDate": "2024-01-01",
    "expiryDays": 0,
    "expiryText": "今天",
    "urgent": true,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

---

### 3.6 购物清单接口

#### 3.6.1 获取购物清单列表

- **接口路径**: `GET /api/shopping-lists`
- **请求头**: `Authorization: Bearer {token}`
- **查询参数**:
  - `page`: 页码（默认 1）
  - `pageSize`: 每页数量（默认 20）
  - `completed`: 是否只显示已完成（可选，true/false）
- **响应数据**:

```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "list": [
      {
        "id": "清单ID",
        "name": "购物清单",
        "items": [
          {
            "id": "购物项ID",
            "name": "西红柿",
            "amount": "2个",
            "price": 4.5,
            "checked": false
          }
        ],
        "totalPrice": 96.7,
        "createdAt": "2024-01-01T00:00:00Z",
        "completedAt": null
      }
    ],
    "total": 10,
    "page": 1,
    "pageSize": 20
  }
}
```

#### 3.6.2 获取当前购物清单

- **接口路径**: `GET /api/shopping-lists/current`
- **请求头**: `Authorization: Bearer {token}`
- **响应数据**:

```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "id": "清单ID",
    "name": "购物清单",
    "items": [
      {
        "id": "购物项ID",
        "name": "西红柿",
        "amount": "2个",
        "price": 4.5,
        "checked": false
      }
    ],
    "totalPrice": 96.7,
    "createdAt": "2024-01-01T00:00:00Z",
    "completedAt": null
  }
}
```

#### 3.6.3 创建购物清单

- **接口路径**: `POST /api/shopping-lists`
- **请求头**: `Authorization: Bearer {token}`
- **请求参数**:

```json
{
  "name": "购物清单（可选）",
  "items": [
    {
      "name": "西红柿",
      "amount": "2个",
      "price": 4.5
    }
  ]
}
```

- **响应数据**: 同获取当前购物清单

#### 3.6.4 更新购物清单

- **接口路径**: `PUT /api/shopping-lists/{listId}`
- **请求头**: `Authorization: Bearer {token}`
- **请求参数**:

```json
{
  "name": "新名称（可选）",
  "items": [
    {
      "id": "购物项ID（更新时必填）",
      "name": "西红柿",
      "amount": "2个",
      "price": 4.5,
      "checked": false
    }
  ]
}
```

- **响应数据**: 同获取当前购物清单

#### 3.6.5 添加购物项

- **接口路径**: `POST /api/shopping-lists/{listId}/items`
- **请求头**: `Authorization: Bearer {token}`
- **请求参数**:

```json
{
  "name": "西红柿",
  "amount": "2个",
  "price": 4.5
}
```

- **响应数据**:

```json
{
  "code": 200,
  "message": "添加成功",
  "data": {
    "id": "购物项ID",
    "name": "西红柿",
    "amount": "2个",
    "price": 4.5,
    "checked": false
  }
}
```

#### 3.6.6 更新购物项

- **接口路径**: `PUT /api/shopping-lists/{listId}/items/{itemId}`
- **请求头**: `Authorization: Bearer {token}`
- **请求参数**:

```json
{
  "name": "西红柿（可选）",
  "amount": "3个（可选）",
  "price": 5.0（可选）,
  "checked": true（可选）
}
```

- **响应数据**: 同添加购物项

#### 3.6.7 删除购物项

- **接口路径**: `DELETE /api/shopping-lists/{listId}/items/{itemId}`
- **请求头**: `Authorization: Bearer {token}`
- **响应数据**:

```json
{
  "code": 200,
  "message": "删除成功",
  "data": null
}
```

#### 3.6.8 完成购物清单

- **接口路径**: `POST /api/shopping-lists/{listId}/complete`
- **请求头**: `Authorization: Bearer {token}`
- **响应数据**:

```json
{
  "code": 200,
  "message": "完成成功",
  "data": {
    "id": "清单ID",
    "completedAt": "2024-01-01T00:00:00Z"
  }
}
```

#### 3.6.9 分享购物清单

- **接口路径**: `POST /api/shopping-lists/{listId}/share`
- **请求头**: `Authorization: Bearer {token}`
- **响应数据**:

```json
{
  "code": 200,
  "message": "分享成功",
  "data": {
    "shareUrl": "分享链接",
    "shareCode": "分享码（可选）"
  }
}
```

---

### 3.7 随机推荐接口

#### 3.7.1 随机推荐菜品

- **接口路径**: `POST /api/recipes/random`
- **请求头**: `Authorization: Bearer {token}`
- **请求参数**:

```json
{
  "mode": "推荐模式（inventory/random/quick）",
  "maxTime": "最大制作时间（分钟，quick模式时必填）"
}
```

- **说明**:
  - `inventory`: 使用库存优先（智能匹配家中现有食材）
  - `random`: 完全随机
  - `quick`: 快手菜（≤20 分钟）
- **响应数据**:

```json
{
  "code": 200,
  "message": "推荐成功",
  "data": {
    "recipe": {
      "id": "菜谱ID",
      "name": "菜谱名称",
      "image": "图片URL",
      "time": "15分钟",
      "difficulty": "简单",
      "tags": ["常做"],
      "tagColors": ["bg-blue-500"],
      "favorite": false,
      "categories": ["家常菜", "酸甜"]
    },
    "reason": "推荐理由（可选）"
  }
}
```

---

### 3.8 用户统计接口

#### 3.8.1 获取用户统计数据

- **接口路径**: `GET /api/user/stats`
- **请求头**: `Authorization: Bearer {token}`
- **查询参数**:
  - `month`: 月份（可选，格式：YYYY-MM，默认当前月）
- **响应数据**:

```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "userId": "用户ID",
    "monthlyCookingCount": 24,
    "wasteReductionRate": 12.5,
    "totalRecipes": 50,
    "favoriteRecipes": 15,
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

---

### 3.9 家庭成员偏好接口

#### 3.9.1 获取家庭成员偏好

- **接口路径**: `GET /api/user/preferences`
- **请求头**: `Authorization: Bearer {token}`
- **响应数据**:

```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "familyMembers": [
      {
        "id": "成员ID",
        "name": "成员名称",
        "preferences": {
          "tastes": ["酸甜", "清淡"],
          "allergies": ["花生", "海鲜"],
          "dislikes": ["苦瓜", "香菜"]
        }
      }
    ]
  }
}
```

#### 3.9.2 更新家庭成员偏好

- **接口路径**: `PUT /api/user/preferences`
- **请求头**: `Authorization: Bearer {token}`
- **请求参数**:

```json
{
  "familyMembers": [
    {
      "id": "成员ID（更新时必填，新增时不填）",
      "name": "成员名称",
      "preferences": {
        "tastes": ["酸甜", "清淡"],
        "allergies": ["花生", "海鲜"],
        "dislikes": ["苦瓜", "香菜"]
      }
    }
  ]
}
```

- **响应数据**: 同获取家庭成员偏好

---

### 3.10 购物订单历史接口

#### 3.10.1 获取购物订单历史

- **接口路径**: `GET /api/shopping-lists/history`
- **请求头**: `Authorization: Bearer {token}`
- **查询参数**:
  - `page`: 页码（默认 1）
  - `pageSize`: 每页数量（默认 20）
  - `startDate`: 开始日期（可选，格式：YYYY-MM-DD）
  - `endDate`: 结束日期（可选，格式：YYYY-MM-DD）
- **响应数据**:

```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "list": [
      {
        "id": "清单ID",
        "name": "购物清单",
        "totalPrice": 96.7,
        "itemCount": 3,
        "completedAt": "2024-01-01T00:00:00Z"
      }
    ],
    "total": 50,
    "page": 1,
    "pageSize": 20
  }
}
```

---

## 四、通用响应格式

### 4.1 成功响应

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {}
}
```

### 4.2 错误响应

```json
{
  "code": 400,
  "message": "错误信息",
  "data": null
}
```

### 4.3 错误码说明

| 错误码 | 说明                       | 处理建议                       |
| ------ | -------------------------- | ------------------------------ |
| `200`  | 成功                       | 正常处理响应数据               |
| `400`  | 请求参数错误               | 检查请求参数格式和必填项       |
| `401`  | 未授权（Token 无效或过期） | 重新登录获取新 Token           |
| `403`  | 无权限                     | 检查用户权限或联系管理员       |
| `404`  | 资源不存在                 | 检查资源 ID 是否正确           |
| `422`  | 数据验证失败               | 检查数据格式和业务规则         |
| `429`  | 请求频率过高               | 降低请求频率，稍后重试         |
| `500`  | 服务器内部错误             | 记录错误信息，联系后端开发人员 |
| `503`  | 服务不可用                 | 稍后重试或联系运维人员         |

### 4.4 错误响应示例

#### 参数错误示例

```json
{
  "code": 400,
  "message": "请求参数错误：菜谱名称不能为空",
  "data": null,
  "errors": [
    {
      "field": "name",
      "message": "菜谱名称不能为空"
    }
  ]
}
```

#### Token 过期示例

```json
{
  "code": 401,
  "message": "Token 已过期，请重新登录",
  "data": null
}
```

#### 资源不存在示例

```json
{
  "code": 404,
  "message": "菜谱不存在",
  "data": null
}
```

### 4.5 前端错误处理建议

1. **统一错误处理**: 建议封装统一的错误处理函数
2. **Token 过期处理**: 401 错误时自动跳转登录页
3. **网络错误处理**: 处理网络超时、连接失败等情况
4. **用户友好提示**: 将技术错误信息转换为用户可理解的提示

```javascript
// 错误处理示例
async function handleApiError(response) {
  if (response.code === 401) {
    // Token 过期，清除本地存储并跳转登录
    localStorage.removeItem("token");
    router.push("/login");
    return;
  }

  if (response.code === 400) {
    // 参数错误，显示具体错误信息
    showToast(response.message || "请求参数错误");
    return;
  }

  // 其他错误统一处理
  showToast(response.message || "操作失败，请稍后重试");
}
```

---

## 五、接口调用流程

### 5.1 用户认证流程

```
1. 用户登录/注册
   POST /api/auth/login 或 POST /api/auth/register
   ↓
2. 获取 Token 和用户信息
   ↓
3. 保存 Token 到本地存储
   ↓
4. 后续请求携带 Token
   Header: Authorization: Bearer {token}
```

### 5.2 典型业务流程

#### 首页数据加载流程

```
1. 获取今日菜单
   GET /api/today-menu
   ↓
2. 获取即将过期食材
   GET /api/ingredients/expiring?days=3
   ↓
3. 渲染首页数据
```

#### 菜谱浏览流程

```
1. 获取菜谱列表
   GET /api/recipes/my?page=1&pageSize=20
   ↓
2. 用户点击菜谱
   ↓
3. 获取菜谱详情
   GET /api/recipes/{recipeId}
   ↓
4. 显示菜谱详情
```

#### 点餐流程

```
1. 浏览菜品列表
   GET /api/meals/recipes
   ↓
2. 添加菜品到点餐清单（前端本地管理）
   ↓
3. 确认点餐
   POST /api/meals/orders
   ↓
4. 确认提交
   POST /api/meals/orders/{orderId}/confirm
```

### 5.3 接口依赖关系

- **必须先调用**: 用户登录接口，获取 Token
- **可选调用**: 用户信息接口，用于更新用户信息
- **独立调用**: 大部分业务接口可以独立调用，不依赖其他接口

---

## 六、接口规范说明

### 5.1 请求头规范

- 所有需要认证的接口必须在请求头中包含：`Authorization: Bearer {token}`
- Content-Type: `application/json`

### 5.2 分页规范

- 所有列表接口支持分页
- 默认页码：1
- 默认每页数量：20
- 最大每页数量：100

### 5.3 时间格式

- 所有时间字段使用 ISO 8601 格式：`YYYY-MM-DDTHH:mm:ssZ`
- 日期字段使用格式：`YYYY-MM-DD`

### 5.4 图片上传

- 图片上传接口：`POST /api/upload/image`
- 请求格式：`multipart/form-data`
- 响应数据：

```json
{
  "code": 200,
  "message": "上传成功",
  "data": {
    "url": "图片URL"
  }
}
```

### 5.5 筛选参数说明

- 多值筛选使用逗号分隔，如：`tastes=酸甜,麻辣`
- 数组参数在 URL 中重复使用参数名，如：`tastes=酸甜&tastes=麻辣`

---

## 七、数据同步说明

### 6.1 实时性要求

- 菜谱、食材、购物清单等核心数据需要实时同步
- 统计数据可以延迟更新（建议 5 分钟内）

### 6.2 缓存策略

- 菜谱列表、网络菜谱等可以缓存，建议缓存时间：5 分钟
- 用户信息、统计数据可以缓存，建议缓存时间：10 分钟

---

## 八、安全要求

### 7.1 认证机制

- 使用 JWT Token 进行用户认证
- Token 有效期：7 天
- 支持 Token 刷新机制

### 7.2 权限控制

- 用户只能操作自己的数据（菜谱、食材、购物清单等）
- 网络菜谱为公共资源，所有用户可查看
- 用户只能修改自己创建的菜谱

### 7.3 数据验证

- 所有输入参数必须进行验证
- 字符串长度限制、数值范围限制等
- 防止 SQL 注入、XSS 攻击等

---

## 九、性能要求

### 8.1 响应时间

- 列表查询接口：< 500ms
- 详情查询接口：< 300ms
- 创建/更新接口：< 1000ms

### 8.2 并发支持

- 支持至少 1000 并发用户
- 数据库连接池配置合理

---

## 十、扩展性考虑

### 9.1 未来可能的功能扩展

- 菜谱评分和评论
- 菜谱分享到社交平台
- 食材价格趋势分析
- 智能推荐算法优化
- 多用户家庭共享功能
- 菜谱视频教程

### 9.2 接口扩展建议

- 预留扩展字段（如：`extra` JSON 字段）
- 使用版本号管理 API（如：`/api/v1/recipes`）
- 支持字段选择（如：`fields=id,name,image`）

---

## 十一、测试要求

### 10.1 单元测试

- 所有业务逻辑需要单元测试覆盖
- 测试覆盖率：> 80%

### 10.2 接口测试

- 所有接口需要编写接口测试用例
- 覆盖正常流程和异常流程

### 10.3 性能测试

- 进行压力测试和负载测试
- 确保满足性能要求

---

## 附录：数据字典

### 难度枚举

- `简单`
- `中等`
- `困难`

### 存储分类枚举

- `room`: 常温
- `fridge`: 冷藏
- `freezer`: 冷冻

### 餐点类型枚举

- `早餐`
- `午餐`
- `晚餐`
- `夜宵`

### 点餐状态

- `pending`: 待确认
- `confirmed`: 已确认
- `completed`: 已完成

### 口味枚举

- `清淡`
- `咸鲜`
- `酸甜`
- `麻辣`
- `酸辣`

### 菜系枚举

- `家常菜`
- `川菜`
- `粤菜`
- `鲁菜`
- `浙菜`
- `湘菜`
- `西餐`

---

## 📋 前后端对接检查清单

### 对接前准备

- [ ] 确认后端服务已部署并可访问
- [ ] 确认基础 URL 配置正确（开发/测试/生产环境）
- [ ] 确认接口文档版本与后端实现版本一致
- [ ] 准备测试账号和测试数据

### 接口对接检查

#### 认证相关

- [ ] 登录接口正常，能获取 Token
- [ ] Token 存储和刷新机制正常
- [ ] 需要认证的接口能正确携带 Token
- [ ] Token 过期时能正确处理（401 错误）

#### 数据格式检查

- [ ] 请求参数格式正确（JSON 格式）
- [ ] 响应数据格式符合文档定义
- [ ] 字段类型匹配（String/Integer/Boolean/Array/Object）
- [ ] 时间格式正确（ISO 8601）
- [ ] 日期格式正确（YYYY-MM-DD）

#### 错误处理检查

- [ ] 参数错误（400）能正确显示错误信息
- [ ] 未授权（401）能跳转登录
- [ ] 资源不存在（404）能正确提示
- [ ] 服务器错误（500）有友好提示
- [ ] 网络错误有重试机制

#### 业务功能检查

- [ ] 列表接口分页功能正常
- [ ] 搜索和筛选功能正常
- [ ] 创建/更新/删除操作正常
- [ ] 数据同步及时（实时/延迟）
- [ ] 图片上传功能正常

### 常见问题排查

1. **接口返回 404**

   - 检查接口路径是否正确
   - 检查基础 URL 是否正确
   - 检查接口版本号

2. **接口返回 401**

   - 检查 Token 是否正确携带
   - 检查 Token 是否过期
   - 检查 Token 格式是否正确（Bearer {token}）

3. **接口返回 400**

   - 检查请求参数格式
   - 检查必填字段是否都传了
   - 检查参数类型是否正确

4. **数据格式不匹配**

   - 检查字段名称是否一致（注意大小写）
   - 检查字段类型是否一致
   - 检查数组/对象结构是否正确

5. **图片上传失败**
   - 检查请求格式是否为 multipart/form-data
   - 检查文件大小限制
   - 检查文件类型限制

### 对接完成确认

- [ ] 所有核心功能接口已对接完成
- [ ] 错误处理机制完善
- [ ] 数据格式验证通过
- [ ] 性能满足要求（响应时间）
- [ ] 测试用例通过
- [ ] 前后端联调通过

---

## 📞 联系方式

**前端负责人**: [待填写]  
**后端负责人**: [待填写]  
**技术支持**: [待填写]

**问题反馈**: 如发现文档与实际接口不一致，请及时反馈给开发团队

---

**文档版本**: v1.0  
**最后更新**: 2024-01-01  
**维护人员**: 开发团队
