package com.backendcam.backendcam.util;

import com.backendcam.backendcam.model.dto.PageResponse;

import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

public class PaginationUtil {

    public static <T, R> PageResponse<List<R>> createPaginationResponse(
            List<T> items,
            long totalItems,
            int page,
            int limit,
            Function<T, R> mapper) {
        
        List<R> mappedData = items.stream()
                .map(mapper)
                .collect(Collectors.toList());

        PageResponse<List<R>> response = new PageResponse<>();
        response.setData(mappedData);

        PageResponse.Meta meta = new PageResponse.Meta();
        meta.setCurrentPage(page);
        meta.setLimit(limit);
        meta.setTotalItems(totalItems);
        
        if (limit > 0) {
            meta.setTotalPages((int) Math.ceil((double) totalItems / limit));
            meta.setHasNext(page < meta.getTotalPages());
            meta.setHasPrevious(page > 1);
        } else {
            meta.setTotalPages(1);
            meta.setHasNext(false);
            meta.setHasPrevious(false);
        }
        
        response.setMeta(meta);

        return response;
    }
}
