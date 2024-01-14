package utils

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"strings"
)

func GetHashValue(text string, key string) string {
	h := hmac.New(sha256.New, []byte(key))
	h.Write([]byte(text))
	hashBytes := h.Sum(nil)
	return strings.ToLower(hex.EncodeToString(hashBytes))
}
