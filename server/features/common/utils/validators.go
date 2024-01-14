package utils

import (
	"fmt"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"regexp"
	"strings"
)

var (
	ErrNoEmailAddress      = status.Errorf(codes.InvalidArgument, "email address is required")
	ErrInvalidEmailAddress = status.Errorf(codes.InvalidArgument, "invalid email address")

	ErrNoPassword      = status.Errorf(codes.InvalidArgument, "password cannot be empty")
	ErrInvalidPassword = status.Errorf(codes.InvalidArgument, "password must be at least 8 characters long and may contain at least one special character")

	ErrNoPhoneNumber       = status.Errorf(codes.InvalidArgument, "phone number is required")
	ErrInvalidPhoneNumber  = status.Errorf(codes.InvalidArgument, "invalid phone number")
	ErrPhoneNumberDialCode = status.Errorf(codes.InvalidArgument, "country code is required")
)

func ValidateEmail(email string) error {
	if len(email) == 0 {
		return ErrNoEmailAddress
	}
	emailRegex := `^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,4}$`
	if ok, _ := regexp.MatchString(emailRegex, email); !ok {
		return ErrInvalidEmailAddress
	}

	return nil
}

func ValidatePassword(password string) error {
	passwordRegex := `^[a-zA-Z0-9!@#$&()\-.+]{8,}$`
	if len(password) == 0 {
		return ErrNoPassword
	}
	if ok, _ := regexp.MatchString(passwordRegex, password); !ok {
		return ErrInvalidPassword
	}

	return nil
}

func ValidatePhoneNumber(phoneNumber, countryCode string) error {
	if len(phoneNumber) == 0 {
		return ErrNoPhoneNumber
	}

	if len(countryCode) == 0 {
		return ErrPhoneNumberDialCode
	}

	// if dial code is provided, reformat the phone number to include the dial code
	if len(countryCode) > 0 && strings.HasPrefix(phoneNumber, "0") {
		phoneNumber = fmt.Sprintf("%s%s", countryCode, strings.TrimLeft(phoneNumber, "0"))
	}

	// valid phone numbers: 0241234567, 233241234567, +233241234567
	phoneNumberWithDialCodeRegex := fmt.Sprintf(`^(\%s|0)[0-9]{9,12}$`, countryCode)
	if ok, _ := regexp.MatchString(phoneNumberWithDialCodeRegex, phoneNumber); !ok {
		return ErrInvalidPhoneNumber
	}

	return nil
}
