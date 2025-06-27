package errors

import (
	"errors"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestAppError(t *testing.T) {
	t.Run("New creates AppError correctly", func(t *testing.T) {
		err := New(ErrorTypeValidation, CodeStoryTooShort, "Story is too short")

		assert.NotNil(t, err)
		assert.Equal(t, ErrorTypeValidation, err.Type)
		assert.Equal(t, CodeStoryTooShort, err.Code)
		assert.Equal(t, "Story is too short", err.Message)
		assert.Nil(t, err.Cause)
	})

	t.Run("Wrap wraps error correctly", func(t *testing.T) {
		originalErr := errors.New("original error")
		err := Wrap(originalErr, ErrorTypeExternal, CodeOpenAIAPIError, "OpenAI API failed")

		assert.NotNil(t, err)
		assert.Equal(t, ErrorTypeExternal, err.Type)
		assert.Equal(t, CodeOpenAIAPIError, err.Code)
		assert.Equal(t, "OpenAI API failed", err.Message)
		assert.Equal(t, originalErr, err.Cause)
	})

	t.Run("Error method returns correct string", func(t *testing.T) {
		t.Run("without cause", func(t *testing.T) {
			err := New(ErrorTypeValidation, CodeStoryTooShort, "Story is too short")
			assert.Equal(t, "STORY_TOO_SHORT: Story is too short", err.Error())
		})

		t.Run("with cause", func(t *testing.T) {
			originalErr := errors.New("original error")
			err := Wrap(originalErr, ErrorTypeExternal, CodeOpenAIAPIError, "OpenAI API failed")
			assert.Equal(t, "OPENAI_API_ERROR: OpenAI API failed (caused by: original error)", err.Error())
		})
	})

	t.Run("Unwrap returns cause", func(t *testing.T) {
		originalErr := errors.New("original error")
		err := Wrap(originalErr, ErrorTypeExternal, CodeOpenAIAPIError, "OpenAI API failed")

		unwrapped := err.Unwrap()
		assert.Equal(t, originalErr, unwrapped)
	})

	t.Run("WithDetails adds details correctly", func(t *testing.T) {
		err := New(ErrorTypeValidation, CodeStoryTooShort, "Story is too short")
		_ = err.WithDetails("minLength", 270).WithDetails("actualLength", 250)

		assert.NotNil(t, err.Details)
		assert.Equal(t, 270, err.Details["minLength"])
		assert.Equal(t, 250, err.Details["actualLength"])
	})

	t.Run("IsAppError identifies AppError correctly", func(t *testing.T) {
		appErr := New(ErrorTypeValidation, CodeStoryTooShort, "Story is too short")
		normalErr := errors.New("normal error")

		assert.True(t, IsAppError(appErr))
		assert.False(t, IsAppError(normalErr))
	})

	t.Run("GetAppError converts correctly", func(t *testing.T) {
		appErr := New(ErrorTypeValidation, CodeStoryTooShort, "Story is too short")
		normalErr := errors.New("normal error")

		t.Run("with AppError", func(t *testing.T) {
			converted, ok := GetAppError(appErr)
			assert.True(t, ok)
			assert.Equal(t, appErr, converted)
		})

		t.Run("with normal error", func(t *testing.T) {
			converted, ok := GetAppError(normalErr)
			assert.False(t, ok)
			assert.Nil(t, converted)
		})
	})
}
