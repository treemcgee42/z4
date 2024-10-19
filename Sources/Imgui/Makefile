INCLUDE_DIR = include
IMGUI_DIR = imgui

# Find all .cpp and .h files in the imgui directory (excluding subdirectories)
IMGUI_FILES = $(shell find $(IMGUI_DIR) -maxdepth 1 -type f \( -name "*.cpp" -o -name "*.h" \))

# Explicitly include the backends files
BACKEND_FILES = $(IMGUI_DIR)/backends/imgui_impl_glfw.cpp $(IMGUI_DIR)/backends/imgui_impl_glfw.h

# Define the symlinks for the imgui/ files (same as their original names)
SYMLINKS = $(IMGUI_FILES:$(IMGUI_DIR)/%=$(INCLUDE_DIR)/%)

# Define the symlinks for the backend files (remove "backends/" prefix)
SYMLINKS += $(patsubst $(IMGUI_DIR)/backends/%, $(INCLUDE_DIR)/%, $(BACKEND_FILES))

symlinks: $(SYMLINKS)

# Rule to create symlinks for files in the main imgui directory
$(INCLUDE_DIR)/%: $(IMGUI_DIR)/%
	@echo "Creating symlink: $@ -> $<"
	@ln -sf $(abspath $<) $@

# Rule to create symlinks for backend files (remove "backends/" from the target name)
$(INCLUDE_DIR)/%: $(IMGUI_DIR)/backends/%
	@echo "Creating symlink: $@ -> $<"
	@ln -sf $(abspath $<) $@

clean-symlinks:
	@echo "Removing symlinks"
	@find $(INCLUDE_DIR) -type l -delete
