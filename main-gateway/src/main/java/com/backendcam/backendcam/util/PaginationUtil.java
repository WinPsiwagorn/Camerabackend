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
            int pageSize,
            Function<T, R> mapper) {
        
        List<R> mappedData = items.stream()
                .map(mapper)
                .collect(Collectors.toList());

        PageResponse<List<R>> response = new PageResponse<>();
        response.setData(mappedData);

        PageResponse.Meta meta = new PageResponse.Meta();
        meta.setCurrentPage(page);
        meta.setPageSize(pageSize);
        meta.setTotalItems(totalItems);
        meta.setTotalPages((int) Math.ceil((double) totalItems / pageSize));
        meta.setHasNext(page < meta.getTotalPages());
        meta.setHasPrevious(page > 1);
        response.setMeta(meta);

        return response;
    }
}
