<?php
// Simple JWT implementation for mobile app authentication
// In production, use a proper JWT library like firebase/php-jwt

class JWT {
    private static $secret = 'cash_in_out_app_secret_key_2024_secure';
    private static $algorithm = 'HS256';
    
    public static function encode($payload) {
        $header = json_encode(['typ' => 'JWT', 'alg' => self::$algorithm]);
        $payload = json_encode($payload);
        
        $base64Header = self::base64url_encode($header);
        $base64Payload = self::base64url_encode($payload);
        
        $signature = hash_hmac('sha256', $base64Header . "." . $base64Payload, self::$secret, true);
        $base64Signature = self::base64url_encode($signature);
        
        return $base64Header . "." . $base64Payload . "." . $base64Signature;
    }
    
    public static function decode($token) {
        error_log("JWT decode called with token: " . $token);
        
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            error_log("JWT decode failed: Invalid token format (parts count: " . count($parts) . ")");
            return false;
        }
        
        $header = json_decode(self::base64url_decode($parts[0]), true);
        $payload = json_decode(self::base64url_decode($parts[1]), true);
        $signature = self::base64url_decode($parts[2]);
        
        error_log("JWT header: " . json_encode($header));
        error_log("JWT payload: " . json_encode($payload));
        
        if (!$header || !$payload) {
            error_log("JWT decode failed: Invalid header or payload");
            return false;
        }
        
        // Verify signature
        $expectedSignature = hash_hmac('sha256', $parts[0] . "." . $parts[1], self::$secret, true);
        if (!hash_equals($signature, $expectedSignature)) {
            error_log("JWT decode failed: Signature verification failed");
            return false;
        }
        
        // Check if token is expired
        if (isset($payload['exp'])) {
            $currentTime = time();
            error_log("JWT expiration check: current time: $currentTime, exp: {$payload['exp']}");
            if ($payload['exp'] < $currentTime) {
                error_log("JWT decode failed: Token expired");
                return false;
            }
        }
        
        error_log("JWT decode successful");
        return $payload;
    }
    
    private static function base64url_encode($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
    
    private static function base64url_decode($data) {
        return base64_decode(strtr($data, '-_', '+/') . str_repeat('=', 3 - (3 + strlen($data)) % 4));
    }
}
?>
