package com.backendcam.backendcam.model.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PageResponse<T> {
    private T data;
    private Meta meta;

    @Getter
    @Setter
    public static class Meta {
        private int currentPage;
        private int limit;
        private long totalItems;
        private int totalPages;
        private boolean hasNext;
        private boolean hasPrevious;
    }
}
