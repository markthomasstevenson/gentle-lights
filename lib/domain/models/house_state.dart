/// Visual state of the house based on current time window and completion status
enum HouseState {
  /// Unresolved - current window is not completed
  dim,
  
  /// Completed for current window (not bedtime)
  warm,
  
  /// Bedtime completed, low light
  night,
}

