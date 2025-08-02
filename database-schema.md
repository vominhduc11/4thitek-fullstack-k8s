# 4THITEK Database Schema - Microservice Architecture

## Tổng quan kiến trúc

Hệ thống sử dụng kiến trúc microservice với database phân tách theo từng service. Dữ liệu tĩnh được lưu trực tiếp trong frontend để tối ưu performance.

---

## 🗂️ Phân bổ Service và Database

### 1. **Auth Service**
Quản lý authentication và authorization

```sql
-- Bảng credentials và phiên đăng nhập
CREATE TABLE user_credentials (
    id VARCHAR(255) PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'user', 'dealer', 'reseller') DEFAULT 'user',
    is_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL
);

CREATE TABLE user_sessions (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    token VARCHAR(500) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user_credentials(id) ON DELETE CASCADE
);

CREATE TABLE user_tokens (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    token VARCHAR(500) NOT NULL,
    type ENUM('reset_password', 'email_verification') NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user_credentials(id) ON DELETE CASCADE
);
```

### 2. **User Service**
Quản lý thông tin profile và hoạt động của user

```sql
CREATE TABLE user_profiles (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) UNIQUE NOT NULL, -- FK to Auth Service
    full_name VARCHAR(255),
    phone VARCHAR(20),
    avatar VARCHAR(500),
    address JSON, -- {street, district, city, province}
    preferences JSON, -- User settings
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE user_activities (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    activity_type ENUM('purchase', 'warranty_claim', 'profile_update', 'login') NOT NULL,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    related_product_id VARCHAR(255) NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    icon VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE purchased_products (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    product_id VARCHAR(255) NOT NULL, -- FK to Product Service
    serial_number VARCHAR(255) UNIQUE NOT NULL,
    purchase_date DATE NOT NULL,
    purchase_location VARCHAR(255),
    dealer VARCHAR(255),
    price DECIMAL(15,2),
    warranty_status ENUM('active', 'expired', 'claimed') DEFAULT 'active',
    warranty_end_date DATE,
    remaining_days INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### 3. **Product Service**
Quản lý catalog sản phẩm

```sql
CREATE TABLE product_categories (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    slug VARCHAR(255) UNIQUE NOT NULL,
    is_visible BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE products (
    -- Primary Keys & Identifiers
    id VARCHAR(255) PRIMARY KEY,
    sku VARCHAR(255) UNIQUE NOT NULL,
    
    -- Basic Info
    name VARCHAR(500) NOT NULL,
    subtitle VARCHAR(500),
    model VARCHAR(255),
    description TEXT,
    long_description TEXT,
    
    -- Pricing & Inventory
    price DECIMAL(15,2),
    price_display VARCHAR(50), -- Formatted price string
    stock INTEGER DEFAULT 0,
    sold INTEGER DEFAULT 0,
    status ENUM('active', 'inactive', 'out_of_stock', 'discontinued') DEFAULT 'active',
    
    -- Category & Classification
    category_id VARCHAR(255),
    tags JSON, -- Array of tags
    target_audience JSON, -- Array of target audiences
    use_cases JSON, -- Array of use cases
    
    -- Media
    images JSON, -- Array of image objects
    videos JSON, -- Array of video objects
    primary_image VARCHAR(500),
    
    -- Technical Specifications
    specifications JSON, -- Complete specs object
    features JSON, -- Array of feature objects
    highlights JSON, -- Array of highlight strings
    
    -- Availability & Business
    availability_status ENUM('available', 'pre-order', 'coming-soon', 'discontinued') DEFAULT 'available',
    release_date TIMESTAMP NULL,
    estimated_delivery VARCHAR(255),
    
    -- Warranty
    warranty_period VARCHAR(100),
    warranty_coverage JSON,
    warranty_conditions JSON,
    warranty_excludes JSON,
    warranty_registration_required BOOLEAN DEFAULT false,
    
    -- Wholesale
    wholesale_discount DECIMAL(5,2) DEFAULT 0,
    min_wholesale_qty INTEGER DEFAULT 10,
    
    -- Relationships
    related_product_ids JSON,
    accessories JSON,
    
    -- Metrics & SEO
    popularity INTEGER DEFAULT 0,
    rating DECIMAL(3,2),
    review_count INTEGER DEFAULT 0,
    seo_title VARCHAR(255),
    seo_description TEXT,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    published_at TIMESTAMP NULL,
    
    -- Foreign Keys
    FOREIGN KEY (category_id) REFERENCES product_categories(id),
    
    -- Indexes
    INDEX idx_category (category_id),
    INDEX idx_status (status),
    INDEX idx_availability (availability_status),
    INDEX idx_popularity (popularity),
    INDEX idx_sku (sku),
    FULLTEXT INDEX idx_search (name, subtitle, description)
);

CREATE TABLE product_certifications (
    id VARCHAR(255) PRIMARY KEY,
    product_id VARCHAR(255) NOT NULL,
    certification_type ENUM('CE', 'FCC', 'ROHS', 'ISO') NOT NULL,
    certificate_number VARCHAR(255),
    issue_date DATE,
    expiry_date DATE,
    is_active BOOLEAN DEFAULT true,
    certificate_file VARCHAR(500),
    test_report VARCHAR(500),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);
```

### 4. **Warranty Service**
Quản lý bảo hành và dịch vụ

```sql
CREATE TABLE warranty_registrations (
    id VARCHAR(255) PRIMARY KEY,
    product_id VARCHAR(255) NOT NULL, -- FK to Product Service
    user_id VARCHAR(255) NOT NULL, -- FK to User Service
    serial_number VARCHAR(255) UNIQUE NOT NULL,
    purchase_date DATE NOT NULL,
    purchase_location VARCHAR(255),
    warranty_plan_id VARCHAR(255),
    warranty_expiry DATE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    customer_info JSON, -- Additional customer details
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE warranty_claims (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL, -- FK to User Service
    product_id VARCHAR(255) NOT NULL, -- FK to Product Service
    claim_number VARCHAR(100) UNIQUE NOT NULL,
    serial_number VARCHAR(255) NOT NULL,
    purchase_date DATE NOT NULL,
    claim_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    issue_description TEXT NOT NULL,
    status ENUM('pending', 'approved', 'rejected', 'in_progress', 'completed') DEFAULT 'pending',
    estimated_completion_date DATE,
    service_center_id VARCHAR(255),
    contact_person JSON, -- Service center contact
    updates JSON, -- Array of status updates
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (service_center_id) REFERENCES service_centers(id)
);

CREATE TABLE service_centers (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(500) NOT NULL,
    city VARCHAR(100) NOT NULL,
    district VARCHAR(100),
    province VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    working_hours JSON, -- {monday: "8:00-17:00", ...}
    services JSON, -- Array of available services
    coordinates_lat DECIMAL(10, 8),
    coordinates_lng DECIMAL(11, 8),
    is_official BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE warranty_faqs (
    id VARCHAR(255) PRIMARY KEY,
    category ENUM('general', 'registration', 'claims', 'coverage') NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    tags JSON, -- Array of tags for filtering
    popularity INTEGER DEFAULT 0,
    related_faqs JSON, -- Array of related FAQ IDs
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### 5. **Content Service (CMS)**
Quản lý blog và nội dung

```sql
CREATE TABLE blog_authors (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    title VARCHAR(255),
    avatar VARCHAR(500),
    bio TEXT,
    social_links JSON, -- {facebook, twitter, linkedin}
    articles_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE blog_categories (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    color VARCHAR(7), -- Hex color
    icon VARCHAR(100),
    posts_count INTEGER DEFAULT 0,
    is_visible BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE blog_tags (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    color VARCHAR(7), -- Hex color
    description TEXT,
    posts_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE blog_posts (
    id VARCHAR(255) PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    slug VARCHAR(500) UNIQUE NOT NULL,
    excerpt TEXT,
    content LONGTEXT NOT NULL,
    featured_image VARCHAR(500),
    author_id VARCHAR(255) NOT NULL,
    category_id VARCHAR(255) NOT NULL,
    published_at TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_published BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    reading_time INTEGER, -- Minutes
    views INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    seo_meta_title VARCHAR(255),
    seo_meta_description TEXT,
    seo_keywords JSON, -- Array of keywords
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES blog_authors(id),
    FOREIGN KEY (category_id) REFERENCES blog_categories(id),
    FULLTEXT INDEX idx_content_search (title, excerpt, content)
);

CREATE TABLE blog_post_tags (
    post_id VARCHAR(255),
    tag_id VARCHAR(255),
    PRIMARY KEY (post_id, tag_id),
    FOREIGN KEY (post_id) REFERENCES blog_posts(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES blog_tags(id) ON DELETE CASCADE
);
```

### 6. **Partner Service**
Quản lý đại lý và đối tác

```sql
CREATE TABLE reseller_locations (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type ENUM('authorized_dealer', 'distributor', 'retail_partner') NOT NULL,
    address JSON, -- {street, district, city, province, postal_code}
    coordinates JSON, -- {lat, lng}
    contact_info JSON, -- {phone, email, website, manager}
    working_hours JSON, -- {monday: "8:00-17:00", ...}
    tier_level ENUM('bronze', 'silver', 'gold', 'platinum') DEFAULT 'bronze',
    is_active BOOLEAN DEFAULT true,
    joined_date DATE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reseller_applications (
    id VARCHAR(255) PRIMARY KEY,
    business_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address JSON, -- Complete address object
    business_type ENUM('retail', 'online', 'distributor', 'system_integrator') NOT NULL,
    target_tier ENUM('bronze', 'silver', 'gold', 'platinum') DEFAULT 'bronze',
    expected_volume INTEGER, -- Expected monthly sales volume
    experience TEXT, -- Business experience description
    status ENUM('pending', 'approved', 'rejected', 'under_review') DEFAULT 'pending',
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP NULL,
    notes TEXT, -- Internal notes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 7. **Certification Service**
Quản lý phòng thí nghiệm và chứng nhận

```sql
CREATE TABLE testing_laboratories (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    country VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    address VARCHAR(500),
    website VARCHAR(255),
    accreditations JSON, -- Array of accreditation bodies
    specializations JSON, -- Array of testing specializations
    certification_standards JSON, -- Array of standards they can certify
    contact_info JSON, -- {phone, email, contact_person}
    is_accredited BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

---

## 📱 Dữ liệu tĩnh trong Frontend

Các dữ liệu sau được lưu trực tiếp trong frontend code để tối ưu performance:

### **constants/certifications.js**
```javascript
export const CERTIFICATION_STANDARDS = {
  CE: { 
    name: "CE", 
    fullName: "Conformité Européenne", 
    logo: "/certs/ce.png",
    description: "European Conformity marking"
  },
  FCC: { 
    name: "FCC", 
    fullName: "Federal Communications Commission", 
    logo: "/certs/fcc.png",
    description: "US communications regulations"
  },
  ROHS: { 
    name: "RoHS", 
    fullName: "Restriction of Hazardous Substances", 
    logo: "/certs/rohs.png",
    description: "EU hazardous substances restriction"
  }
}
```

### **constants/contact.js**
```javascript
export const CONTACT_INFO = {
  phone: "+84 123 456 789",
  email: "info@4thitek.com",
  address: "123 ABC Street, District 1, HCMC",
  workingHours: "8:00 - 17:00 (Thứ 2 - Thứ 6)"
}
```

### **constants/social.js**
```javascript
export const SOCIAL_LINKS = {
  facebook: {
    name: "Facebook",
    url: "https://facebook.com/4thitek",
    icon: "facebook",
    followers: "10K"
  },
  youtube: {
    name: "YouTube", 
    url: "https://youtube.com/4thitek",
    icon: "youtube",
    subscribers: "5K"
  },
  instagram: {
    name: "Instagram",
    url: "https://instagram.com/4thitek", 
    icon: "instagram",
    followers: "8K"
  }
}
```

### **constants/offices.js**
```javascript
export const OFFICE_LOCATIONS = [
  {
    id: 1,
    name: "Trụ sở chính",
    type: "main_office",
    address: {
      street: "123 ABC Street",
      district: "District 1", 
      city: "Ho Chi Minh City",
      province: "Ho Chi Minh"
    },
    coordinates: { lat: 10.7769, lng: 106.7009 },
    phone: "+84 123 456 789",
    email: "info@4thitek.com",
    workingHours: {
      monday: "8:00-17:00",
      tuesday: "8:00-17:00",
      wednesday: "8:00-17:00", 
      thursday: "8:00-17:00",
      friday: "8:00-17:00",
      saturday: "8:00-12:00",
      sunday: "Closed"
    }
  }
]
```

### **constants/departments.js**
```javascript
export const DEPARTMENTS = {
  sales: {
    name: "Phòng Kinh doanh",
    email: "sales@4thitek.com",
    phone: "+84 123 456 790",
    description: "Tư vấn bán hàng và hỗ trợ đại lý"
  },
  support: {
    name: "Phòng Hỗ trợ kỹ thuật", 
    email: "support@4thitek.com",
    phone: "+84 123 456 791",
    description: "Hỗ trợ kỹ thuật và bảo hành"
  },
  warranty: {
    name: "Phòng Bảo hành",
    email: "warranty@4thitek.com", 
    phone: "+84 123 456 792",
    description: "Xử lý yêu cầu bảo hành"
  }
}
```

### **constants/resellerTiers.js**
```javascript
export const RESELLER_TIERS = {
  bronze: {
    name: "Bronze",
    level: 1,
    commission: 5,
    minOrder: 1000000,
    requirements: ["Doanh thu tối thiểu 50 triệu/năm"],
    benefits: ["Chiết khấu 5%", "Hỗ trợ marketing cơ bản"],
    color: "#CD7F32"
  },
  silver: {
    name: "Silver", 
    level: 2,
    commission: 7,
    minOrder: 5000000,
    requirements: ["Doanh thu tối thiểu 200 triệu/năm", "Showroom chính thức"],
    benefits: ["Chiết khấu 7%", "Hỗ trợ marketing nâng cao", "Ưu tiên giao hàng"],
    color: "#C0C0C0"
  },
  gold: {
    name: "Gold",
    level: 3, 
    commission: 10,
    minOrder: 10000000,
    requirements: ["Doanh thu tối thiểu 500 triệu/năm", "Đội ngũ bán hàng chuyên nghiệp"],
    benefits: ["Chiết khấu 10%", "Hỗ trợ marketing toàn diện", "Đào tạo sản phẩm", "Hỗ trợ sự kiện"],
    color: "#FFD700"
  }
}
```

---

## 🔄 Event-Driven Architecture

Để đảm bảo data consistency giữa các microservice, sử dụng event-driven pattern:

### **Key Events:**
- `UserRegistered` - Khi user đăng ký (Auth → User Service)
- `ProductPurchased` - Khi mua sản phẩm (Order → User + Warranty Service)
- `WarrantyRegistered` - Khi đăng ký bảo hành (Warranty → User Service)
- `ProductUpdated` - Khi cập nhật sản phẩm (Product → Warranty Service)

### **Message Queue:**
Sử dụng Kafka/RabbitMQ cho event communication giữa services.

---

## 🚀 Deployment Notes

1. **Database per Service**: Mỗi service có database riêng biệt
2. **API Gateway**: Centralized routing và authentication
3. **Service Discovery**: Consul/Eureka cho service registration
4. **Monitoring**: ELK Stack cho logging, Prometheus cho metrics
5. **Caching**: Redis cho session và frequently accessed data

---

## 📈 Performance Optimizations

1. **Indexes**: Đã định nghĩa indexes cho các trường thường xuyên query
2. **JSON Fields**: Sử dụng JSON cho flexible data structures
3. **Static Data**: Move non-dynamic data to frontend constants
4. **FULLTEXT Search**: Cho product và blog content search
5. **Pagination**: Implement cursor-based pagination cho large datasets

---

*Tài liệu này được tạo dựa trên phân tích chi tiết frontend fe/main và requirements của hệ thống 4THITEK.*