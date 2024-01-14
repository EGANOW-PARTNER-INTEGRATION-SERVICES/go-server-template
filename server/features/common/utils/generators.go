package utils

import (
	"math/rand"
)

// generateDigits generates a random string of digits of the specified length.
func generateDigits(length int) string {
	values := "1234567890"
	var key string

	for i := 0; i < length; i++ {
		key += string(values[rand.Intn(len(values))])
	}

	return key
}

// GenerateSixDigitOTP generates a random string of six digits.
func GenerateSixDigitOTP() string {
	return generateDigits(6)
}
