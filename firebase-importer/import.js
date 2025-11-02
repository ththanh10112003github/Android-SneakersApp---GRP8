const admin = require('firebase-admin');

// 1. CHỈ ĐỊNH TỆP SERVICE ACCOUNT KEY
const serviceAccount = require('./service-account-key.json');

// 2. CHỈ ĐỊNH TỆP DỮ LIỆU JSON
const data = require('./products.json');

// 3. KHỞI TẠO FIREBASE ADMIN
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 4. TÊN COLLECTION BẠN MUỐN THÊM VÀO (phải khớp với tên trên Firebase)
const collectionName = 'products'; 

async function importData() {
  console.log(`Bắt đầu import ${data.length} sản phẩm vào collection '${collectionName}'...`);
  
  // Sử dụng Batch Write để ghi nhiều document cùng lúc
  const batch = db.batch();

  data.forEach((item) => {
    // Lấy ID từ trường 'productId' trong tệp JSON của bạn
    const docId = item.productId;

    // Tạo một tham chiếu đến document với ID CỤ THỂ
    // Điều này đảm bảo ID document = productId của bạn
    const docRef = db.collection(collectionName).doc(docId);
    
    // Thêm thao tác "set" (tạo mới hoặc ghi đè) vào lô
    batch.set(docRef, item);
  });

  // 5. THỰC THI LÔ GHI (COMMIT)
  try {
    await batch.commit();
    console.log('=============================================');
    console.log(`IMPORT THÀNH CÔNG! Đã thêm ${data.length} sản phẩm.`);
    console.log('=============================================');
  } catch (error) {
    console.error('LỖI KHI IMPORT:', error);
  }
}

// 6. GỌI HÀM ĐỂ CHẠY
importData();