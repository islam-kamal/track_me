enum AccountRole {
  user,
  admin;

  static AccountRole parse(Object? value) {
    return value == 'admin' ? AccountRole.admin : AccountRole.user;
  }
}
