#define_import_path tests::shader_loader::root

#import "tests/shader_loader/dep.wgsl"::DEP_VALUE

fn root_value() -> f32 {
    return DEP_VALUE;
}
