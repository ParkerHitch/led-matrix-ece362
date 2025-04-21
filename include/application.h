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

// The function signature that the main frame rendering loop has
typedef void (*RenderFrameFn)(void);

// Your application
typedef struct {
    // Application main function
    RenderFrameFn renderFn;

    // Metadata
    const char* name;
    const char* authorfirst;
    const char* authorlast;
} Application;



// ================
// Helper functions
// ================
#define BLUE 0b100
#define GREEN 0b010
#define RED 0b001
#define TIEL 0b110
#define PURPLE 0b101
#define YELLOW 0b011
#define WHITE 0b111
#define BLACK 0b000

extern void setPixel(int32_t x, int32_t y, int32_t z, uint16_t color);
extern void clearFrame(uint16_t color);
extern void matrixRender();
extern void dtStart();
extern unsigned int dtMili();
extern float dtSeconds();
