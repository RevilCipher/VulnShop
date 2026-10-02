User.destroy_all
Product.destroy_all

User.create!([
  { username: "admin", password: "admin123", role: "admin", balance: 99999 },
  { username: "user",  password: "password", role: "user",  balance: 1500 },
  { username: "alice", password: "alice123", role: "user",  balance: 800 },
  { username: "bob",   password: "bob123",   role: "user",  balance: 300 }
])

Product.create!([
  { name: "Laptop Gaming RTX", description: "Laptop high-end untuk gaming & coding", price: 17500000, stock: 8 },
  { name: "Smartphone Flagship", description: "HP flagship kamera terbaik", price: 12500000, stock: 15 },
  { name: "Headphone Noise Cancelling", description: "Suara jernih + ANC", price: 3200000, stock: 40 },
  { name: "Mechanical Keyboard", description: "Switch blue, RGB", price: 950000, stock: 60 },
  { name: "Monitor 27\" 144Hz", description: "IPS panel, 1ms", price: 4500000, stock: 12 }
])

puts "Seed selesai!"
