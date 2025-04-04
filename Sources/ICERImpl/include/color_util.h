//
//  color_util.h
//  CubesatGS
//
//  Created by Vincent Kwok on 27/4/23.
//

#ifndef color_util_h
#define color_util_h

#include <stdint.h>
#include <stddef.h>

#define CLIP(X) ( (X) > 255 ? 255 : (X) < 0 ? 0 : X)

// YCbCr -> RGB
#define CYCbCr2R(Y, Cb, Cr) CLIP( Y + ( 91881 * Cr >> 16 ) - 179 )
#define CYCbCr2G(Y, Cb, Cr) CLIP( Y - (( 22544 * Cb + 46793 * Cr ) >> 16) + 135)
#define CYCbCr2B(Y, Cb, Cr) CLIP( Y + (116129 * Cb >> 16 ) - 226 )


static inline void
yuv_to_rgb888_inplace(
    uint16_t *y_channel, uint16_t *u_channel, uint16_t *v_channel,
    size_t image_w, size_t image_h, size_t rowstride
) {
    int32_t y, u, v;
    uint8_t r, g, b;

    uint16_t *input_y, *input_u, *input_v;
    for (size_t row = 0; row < image_h; row++) {
        input_y = y_channel + rowstride * row;
        input_u = u_channel + rowstride * row;
        input_v = v_channel + rowstride * row;
        for (size_t col = 0; col < image_w; col++) {
            y = (*input_y);
            u = (*input_u);
            v = (*input_v);

            r = CYCbCr2R(y, u, v);
            g = CYCbCr2G(y, u, v);
            b = CYCbCr2B(y, u, v);
            *input_y = r;
            *input_u = g;
            *input_v = b;

            input_y++;
            input_u++;
            input_v++;
        }
    }
}

#endif /* color_util_h */
