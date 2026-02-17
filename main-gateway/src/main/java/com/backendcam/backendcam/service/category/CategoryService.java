package com.backendcam.backendcam.service.category;

import java.util.List;
import java.util.concurrent.ExecutionException;

import org.springframework.stereotype.Service;

import com.backendcam.backendcam.model.entity.Category;
import com.backendcam.backendcam.repository.CategoryRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;

    public Category createCategory(Category category) throws ExecutionException, InterruptedException {
        return categoryRepository.createCategory(category);
    }

    public Category createCategoryWithId(Category category) throws ExecutionException, InterruptedException {
        return categoryRepository.createCategoryWithId(category);
    }

    public Category getCategoryById(String id) throws ExecutionException, InterruptedException {
        return categoryRepository.getCategoryById(id);
    }

    public List<Category> getAllCategories() throws ExecutionException, InterruptedException {
        return categoryRepository.getAllCategories();
    }

    public Category updateCategory(String id, Category category) throws ExecutionException, InterruptedException {
        return categoryRepository.updateCategory(id, category);
    }

    public boolean deleteCategory(String id) throws ExecutionException, InterruptedException {
        return categoryRepository.deleteCategory(id);
    }
}
