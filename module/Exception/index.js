const { Prisma } = require("@prisma/client");

class ApplicationError extends Error {
  constructor(message) {
    super(message);
    this.name = this.constructor.name;
    this.status = 500;
  }
}

class ValidationError extends ApplicationError {
  constructor(message, details) {
    super(message);
    this.details = details;
    this.status = 422;
  }
}

class NotFoundError extends ApplicationError {
  constructor(message) {
    super(message);
    this.status = 404;
  }
}

class ForbiddenError extends ApplicationError {
  constructor(message) {
    super(message);
    this.status = 403;
  }
}

class UnauthorizedError extends ApplicationError {
  constructor(message) {
    super(message);
    this.status = 401;
  }
}

class UnCaughtError extends ApplicationError {
  constructor(message) {
    super(message);
    this.status = 500;
  }
}

class BadRequestError extends ApplicationError {
  constructor(message) {
    super(message);
    this.status = 400;
  }
}

class DuplicationError extends ApplicationError {
  constructor(message) {
    super(message);
    this.status = 409;
  }
}

module.exports = {
  ApplicationError,
  ValidationError,
  NotFoundError,
  ForbiddenError,
  UnauthorizedError,
  UnCaughtError,
  BadRequestError,
  DuplicationError,
};
