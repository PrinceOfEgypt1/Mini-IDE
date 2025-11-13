/**
 * Custom error classes for Mini-IDE Server
 *
 * @module errors
 * @packageDocumentation
 */

/**
 * Base error class for all Mini-IDE server errors
 *
 * @public
 */
export class MiniIDEError extends Error {
  /**
   * HTTP status code associated with this error
   */
  public readonly statusCode: number;

  /**
   * Error code for categorization
   */
  public readonly code: string;

  /**
   * Creates a new MiniIDEError
   *
   * @param message - Human-readable error message in Portuguese
   * @param statusCode - HTTP status code (default: 500)
   * @param code - Error code for categorization (default: 'INTERNAL_ERROR')
   */
  constructor(message: string, statusCode = 500, code = 'INTERNAL_ERROR') {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.code = code;
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Error thrown when request validation fails
 *
 * @public
 */
export class ValidationError extends MiniIDEError {
  /**
   * Creates a new ValidationError with status code 400
   *
   * @param message - Human-readable validation error message
   * @param code - Error code (default: 'VALIDATION_ERROR')
   */
  constructor(message: string, code = 'VALIDATION_ERROR') {
    super(message, 400, code);
  }
}

/**
 * Error thrown when budget is exceeded
 *
 * @public
 */
export class BudgetExceededError extends MiniIDEError {
  /**
   * Creates a new BudgetExceededError with status code 402
   *
   * @param message - Human-readable budget error message
   * @param code - Error code (default: 'BUDGET_EXCEEDED')
   */
  constructor(message: string, code = 'BUDGET_EXCEEDED') {
    super(message, 402, code);
  }
}

/**
 * Error thrown when LLM service is unavailable
 *
 * @public
 */
export class ServiceUnavailableError extends MiniIDEError {
  /**
   * Suggested retry-after delay in seconds
   */
  public readonly retryAfter?: number;

  /**
   * Creates a new ServiceUnavailableError with status code 503
   *
   * @param message - Human-readable service error message
   * @param retryAfter - Suggested retry delay in seconds
   * @param code - Error code (default: 'SERVICE_UNAVAILABLE')
   */
  constructor(message: string, retryAfter?: number, code = 'SERVICE_UNAVAILABLE') {
    super(message, 503, code);
    this.retryAfter = retryAfter;
  }
}

/**
 * Error thrown for internal server errors
 *
 * @public
 */
export class InternalServerError extends MiniIDEError {
  /**
   * Creates a new InternalServerError with status code 500
   *
   * @param message - Human-readable internal error message
   * @param code - Error code (default: 'INTERNAL_ERROR')
   */
  constructor(message: string, code = 'INTERNAL_ERROR') {
    super(message, 500, code);
  }
}
