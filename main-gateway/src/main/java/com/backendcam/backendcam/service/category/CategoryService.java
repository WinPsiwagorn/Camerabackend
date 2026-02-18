package com.backendcam.backendcam.service.category;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.stereotype.Service;

import com.backendcam.backendcam.model.dto.PageResponse;
import com.backendcam.backendcam.model.dto.category.CategoryCreateDTO;
import com.backendcam.backendcam.model.dto.category.CategoryResponseDTO;
import com.backendcam.backendcam.model.entity.Category;
import com.backendcam.backendcam.repository.CategoryRepository;
import com.backendcam.backendcam.util.PaginationUtil;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;

    public CategoryResponseDTO createCategory(CategoryCreateDTO categoryDto) {
        try {
            Category category = new Category();
            category.setName(categoryDto.getName());

            String id = categoryRepository.createCategory(category);
            category.setId(id);
            return toDto(category);
        } catch (Exception e) {
            throw new RuntimeException("Failed to create category", e);
        }
    }

    public Optional<CategoryResponseDTO> getCategoryById(String id) {
        try {
            return categoryRepository.getCategoryById(id)
                    .map(this::toDto);
        } catch (Exception e) {
            throw new RuntimeException("Failed to get category by id", e);
        }
    }

    public List<CategoryResponseDTO> getAllCategories() {
        try {
            return categoryRepository.getAllCategories()
                    .stream()
                    .map(this::toDto)
                    .toList();
        } catch (Exception e) {
            throw new RuntimeException("Failed to get all categories", e);
        }
    }

    public PageResponse<List<CategoryResponseDTO>> getCategoriesByPage(int page, int limit) {
        try {
            List<Category> categories = categoryRepository.getCategoriesByPage(page, limit);
            long totalItems = categoryRepository.getTotalCount();
            
            return PaginationUtil.createPaginationResponse(categories, totalItems, page, limit, this::toDto);
        } catch (Exception e) {
            throw new RuntimeException("Failed to get categories by page", e);
        }
    }

    public Optional<CategoryResponseDTO> updateCategory(String id, Map<String, Object> updates) {
        try {
            Category updatedCategory = categoryRepository.updateCategory(id, updates);
            return Optional.of(toDto(updatedCategory));
        } catch (java.util.NoSuchElementException e) {
            return Optional.empty();
        } catch (Exception e) {
            throw new RuntimeException("Failed to update category", e);
        }
    }

    public boolean deleteCategory(String id) {
        try {
            categoryRepository.deleteCategory(id);
            return true;
        } catch (Exception e) {
            throw new RuntimeException("Failed to delete category", e);
        }
    }

    private CategoryResponseDTO toDto(Category category) {
        return new CategoryResponseDTO(category.getId(), category.getName());
    }
}
