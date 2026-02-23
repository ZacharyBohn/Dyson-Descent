class Shield {
  double shieldStrength;
  double maxShieldStrength;
  double regenerationRate;
  double regenerationDelay;
  double timeSinceHit;

  Shield({
    required this.maxShieldStrength,
    this.regenerationRate = 5,
    this.regenerationDelay = 3,
  })  : shieldStrength = maxShieldStrength,
        timeSinceHit = 0;

  bool get isActive => shieldStrength > 0;

  void absorbDamage(double amount) {
    shieldStrength = (shieldStrength - amount).clamp(0, maxShieldStrength);
    timeSinceHit = 0;
  }

  void update(double deltaTime) {
    timeSinceHit += deltaTime;
    if (timeSinceHit >= regenerationDelay && shieldStrength < maxShieldStrength) {
      shieldStrength =
          (shieldStrength + regenerationRate * deltaTime).clamp(0, maxShieldStrength);
    }
  }
}
