"""
Quick test script for Firebase authentication backend.

This script helps verify that Firebase Admin SDK is properly configured
and can verify tokens.

Usage:
    python test_firebase.py <firebase_id_token>
"""

import sys
from app.core.firebase_init import init_firebase, verify_firebase_token


def test_firebase_setup():
    """Test Firebase initialization."""
    print("Testing Firebase Admin SDK setup...")
    print("-" * 50)
    
    try:
        init_firebase()
        print("✓ Firebase Admin SDK initialized successfully")
        return True
    except Exception as e:
        print(f"✗ Firebase initialization failed: {e}")
        return False


def test_token_verification(token: str):
    """Test Firebase token verification."""
    print("\nTesting Firebase token verification...")
    print("-" * 50)
    
    try:
        decoded_token = verify_firebase_token(token)
        print("✓ Token verified successfully")
        print(f"\nToken details:")
        print(f"  UID: {decoded_token.get('uid')}")
        print(f"  Email: {decoded_token.get('email')}")
        print(f"  Name: {decoded_token.get('name')}")
        print(f"  Email verified: {decoded_token.get('email_verified')}")
        print(f"  Provider: {decoded_token.get('firebase', {}).get('sign_in_provider')}")
        return True
    except Exception as e:
        print(f"✗ Token verification failed: {e}")
        return False


def main():
    """Main test function."""
    print("=" * 50)
    print("Firebase Backend Setup Test")
    print("=" * 50)
    print()
    
    # Test 1: Firebase initialization
    if not test_firebase_setup():
        print("\n❌ Firebase setup test FAILED")
        print("\nMake sure:")
        print("1. serviceAccountKey.json is in the backend/ directory")
        print("2. The file is valid JSON from Firebase Console")
        print("3. You have the correct Firebase project")
        sys.exit(1)
    
    # Test 2: Token verification (if token provided)
    if len(sys.argv) > 1:
        token = sys.argv[1]
        if not test_token_verification(token):
            print("\n❌ Token verification test FAILED")
            print("\nMake sure:")
            print("1. Token is from the same Firebase project")
            print("2. Token hasn't expired (valid for 1 hour)")
            print("3. Firebase project IDs match")
            sys.exit(1)
    else:
        print("\n⚠️  No token provided, skipping token verification test")
        print("   To test token verification, run:")
        print("   python test_firebase.py <firebase_id_token>")
    
    print("\n" + "=" * 50)
    print("✅ All tests PASSED!")
    print("=" * 50)
    print("\nYour backend is ready to accept Firebase authentication!")


if __name__ == "__main__":
    main()
