export type doorModel = Instance | {
    Hinge: BasePart,
    Hitbox: BasePart,
}

export type extension = {
    [string]: any,
    init: (door: any) -> nil
}

return false