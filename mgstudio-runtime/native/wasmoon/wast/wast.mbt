// WAST (WebAssembly Test Script) Parser
// Re-exports the WAST parser from the wat package

///|
pub using @wat { type WastScript }

///|
pub using @wat { type WastCommand }

///|
pub using @wat { type WastModuleSource }

///|
pub using @wat { type WastAction }

///|
pub using @wat { type WastValue }

///|
pub using @wat { type WatError }

///|
pub fn parse(input : String) -> WastScript raise @wat.WatError {
  @wat.parse_wast(input)
}
