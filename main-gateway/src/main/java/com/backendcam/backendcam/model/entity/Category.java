package com.backendcam.backendcam.model.entity;

import com.google.cloud.firestore.annotation.DocumentId;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class Category {
   @DocumentId
   private String id;
   private String name;
}