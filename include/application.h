#include <stdint.h>
#include <stdbool.h>

// ================
// Frame data stuff
// ================

// DMA-friendly representation of a single layer the cube.
// The rendering function can assume that layerId is populated automatically.
typedef struct {
    uint8_t layerId;
    uint8_t srs[24];
} LayerData;

// DMA-friendly representation of an entire frame of data
typedef struct {
    LayerData layers[8];
} FrameBuffer;



// =================
// Application stuff
// =================

// The function signature that the main frame renering loop has
typedef void (*RenderFrameFn)(void);

// Your application
typedef struct {
    // Function that will be run when your app is started
    // Setup all peripherals here
    void (*initFn)(void);

    // Main rendering loop
    // Will be called periodically according to targetFPS
    RenderFrameFn renderFn;

    // Function that will be run when your app stops
    // Free memory and deinit peripherals here
    void (*deinitFn)(void);

    // Metadata
    const char* name;
    const char* authorfirst;
    const char* authorlast;
    uint8_t targetFPS;
    // Optional parameters passed in
    bool needsAccel;
    bool needsJoystick;
} Application;



// ================
// Helper functions
// ================
#define RED 0b100
#define GREEN 0b010
#define BLUE 0b001
extern void set_pixel(FrameBuffer* frame, uint8_t x, uint8_t y, uint8_t z, uint8_t color);


