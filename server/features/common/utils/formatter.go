package utils

import (
	"fmt"
	"strings"
)

func FormatPhoneNumberWithDialCode(phoneNumber string, dialCode string) string {
	if len(phoneNumber) == 0 {
		return ""
	}

	if len(dialCode) == 0 {
		return phoneNumber
	}

	if strings.HasPrefix(phoneNumber, dialCode) {
		return phoneNumber
	}

	return fmt.Sprintf("%s%s", dialCode, strings.TrimLeft(phoneNumber, "0"))
}
