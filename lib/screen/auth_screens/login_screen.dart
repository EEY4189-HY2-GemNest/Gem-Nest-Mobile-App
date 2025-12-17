





















  bool rememberMe = false;















































                          Checkbox(
                            value: rememberMe,
                            onChanged: (value) =>
                                setState(() => rememberMe = value ?? false),
                            activeColor: AppTheme.primaryBlue,
                          ),
                          
