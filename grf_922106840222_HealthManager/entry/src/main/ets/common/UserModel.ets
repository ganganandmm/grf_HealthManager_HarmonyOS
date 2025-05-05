export class User {
  id?: number;
  username: string;
  password: string;
  age?: number;
  gender?: string;
  phone?: string;
  email?: string;
  height?: number;
  weight?: number;
  avatarPath?: string;

  constructor(
    username: string,
    password: string,
    id?: number,
    age?: number,
    gender?: string,
    phone?: string,
    email?: string,
    height?: number,
    weight?: number,
    avatarPath?: string
  ) {
    this.username = username;
    this.password = password;
    this.id = id;
    this.age = age;
    this.gender = gender;
    this.phone = phone;
    this.email = email;
    this.height = height;
    this.weight = weight;
    this.avatarPath = avatarPath;
  }
}