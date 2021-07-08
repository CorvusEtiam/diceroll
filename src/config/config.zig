
// Stub for config file parser

pub const ConfArray = struct {
    items: []ConfValue
};

pub const DateTime = struct {
    date: []u8,
    time: []u8,
    zone: []u8
};

pub const ConfValue = union(enum) {
    boolean: bool,
    string: []u8,
    numeric: f32,
    table: *ConfTable,
    array: *ConfArray,
    datetime: DateTime,
};

pub const ConfEntry = struct {
    field: []u8,
    value: ConfValue,
};

pub const ConfTable = struct {
    table_name: []u8 = undefined,
    entries: []ConfEntry = undefined,
};

pub const ConfWriter = struct {

};

pub const ConfReader = struct {
    pub fn fromReader(alloc: *std.mem.Allocator, reader: anytype) !ConfReader {

    }
    
    pub fn getOrDefault(comptime ValueType: type, path: []const u8, default_value: @TypeOf(ValueType)) @TypeOf(ValueType) {

    }
};
