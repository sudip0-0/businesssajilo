/// Chat text limits — keep in sync with `messages_body_max_len` (migration 22).
abstract final class MessageValidator {
  static const maxBodyLength = 4000;

  static bool isBodyTooLong(String body) => body.length > maxBodyLength;
}
