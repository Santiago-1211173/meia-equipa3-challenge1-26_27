package com.expert.drools.controllers;

import com.expert.drools.dtos.ErrorResponseDto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Global exception handler providing standardized error payloads across all endpoints.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponseDto> handleValidationExceptions(MethodArgumentNotValidException ex) {
        log.warn("Validation error encountered: {}", ex.getMessage());

        List<String> details = ex.getBindingResult()
                .getAllErrors()
                .stream()
                .map(error -> {
                    if (error instanceof FieldError fieldError) {
                        return fieldError.getField() + ": " + fieldError.getDefaultMessage();
                    }
                    return error.getDefaultMessage();
                })
                .collect(Collectors.toList());

        ErrorResponseDto errorDto = ErrorResponseDto.builder()
                .status(HttpStatus.BAD_REQUEST.value())
                .error("Bad Request")
                .message("Input validation failed")
                .details(details)
                .timestamp(Instant.now())
                .build();

        return ResponseEntity.badRequest().body(errorDto);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponseDto> handleJsonParseError(HttpMessageNotReadableException ex) {
        log.warn("Malformed JSON request: {}", ex.getMessage());

        ErrorResponseDto errorDto = ErrorResponseDto.builder()
                .status(HttpStatus.BAD_REQUEST.value())
                .error("Bad Request")
                .message("Malformed JSON request body")
                .details(List.of(ex.getMostSpecificCause().getMessage()))
                .timestamp(Instant.now())
                .build();

        return ResponseEntity.badRequest().body(errorDto);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponseDto> handleGenericException(Exception ex) {
        log.error("Unhandled internal server error: ", ex);

        ErrorResponseDto errorDto = ErrorResponseDto.builder()
                .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
                .error("Internal Server Error")
                .message("An unexpected error occurred while processing the inference request")
                .details(List.of(ex.getMessage() != null ? ex.getMessage() : "Unknown internal error"))
                .timestamp(Instant.now())
                .build();

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorDto);
    }
}
