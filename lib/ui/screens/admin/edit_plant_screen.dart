import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/plant_model.dart';
import '../../../app/constants/app_constants.dart';

class EditPlantScreen extends StatefulWidget {
  final bool isEditing;
  final Plant? plant;

  const EditPlantScreen({
    super.key,
    required this.isEditing,
    this.plant,
  });

  @override
  EditPlantScreenState createState() => EditPlantScreenState();
}

class EditPlantScreenState extends State<EditPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = AppConstants.plantCategories.first;
  final _growthDurationController = TextEditingController();
  String _selectedDifficulty = 'Sedang'; // Default
  final _wateringFrequencyController = TextEditingController();
  final _sunlightRequirementController = TextEditingController();
  final _soilTypeController = TextEditingController();
  final _harvestTimeController = TextEditingController();
  final _benefitsController = TextEditingController();
  
  // Planting steps
  final List<Map<String, dynamic>> _plantingSteps = [];
  
  // Care instructions
  final List<Map<String, dynamic>> _careInstructions = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.isEditing && widget.plant != null) {
      // Populate fields with existing data
      final plant = widget.plant!;
      _nameController.text = plant.name;
      _scientificNameController.text = plant.scientificName;
      _descriptionController.text = plant.description;
      _imageUrlController.text = plant.imageUrl;
      _selectedCategory = plant.category;
      _growthDurationController.text = plant.growthDuration.toString();
      _selectedDifficulty = plant.difficulty;
      _wateringFrequencyController.text = plant.wateringFrequency;
      _sunlightRequirementController.text = plant.sunlightRequirement;
      _soilTypeController.text = plant.soilType;
      _harvestTimeController.text = plant.harvestTime;
      _benefitsController.text = plant.benefits;
      
      // Populate planting steps
      _plantingSteps.addAll(plant.plantingSteps);
      
      // Populate care instructions
      _careInstructions.addAll(plant.careInstructions);
    } else {
      // Add empty step and care instruction for new plant
      _addEmptyPlantingStep();
      _addEmptyCareInstruction();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _growthDurationController.dispose();
    _wateringFrequencyController.dispose();
    _sunlightRequirementController.dispose();
    _soilTypeController.dispose();
    _harvestTimeController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  void _addEmptyPlantingStep() {
    setState(() {
      _plantingSteps.add({
        'stepNumber': _plantingSteps.length + 1,
        'title': '',
        'description': '',
      });
    });
  }

  void _removePlantingStep(int index) {
    setState(() {
      _plantingSteps.removeAt(index);
      
      // Renumber steps
      for (int i = 0; i < _plantingSteps.length; i++) {
        _plantingSteps[i]['stepNumber'] = i + 1;
      }
    });
  }

  void _addEmptyCareInstruction() {
    setState(() {
      _careInstructions.add({
        'title': '',
        'description': '',
      });
    });
  }

  void _removeCareInstruction(int index) {
    setState(() {
      _careInstructions.removeAt(index);
    });
  }

  Future<void> _savePlant() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final firestore = FirebaseFirestore.instance;
        final now = DateTime.now();
        
        final plantData = {
          'name': _nameController.text,
          'scientificName': _scientificNameController.text,
          'description': _descriptionController.text,
          'imageUrl': _imageUrlController.text,
          'category': _selectedCategory,
          'growthDuration': int.tryParse(_growthDurationController.text) ?? 0,
          'difficulty': _selectedDifficulty,
          'wateringFrequency': _wateringFrequencyController.text,
          'sunlightRequirement': _sunlightRequirementController.text,
          'soilType': _soilTypeController.text,
          'harvestTime': _harvestTimeController.text,
          'benefits': _benefitsController.text,
          'plantingSteps': _plantingSteps,
          'careInstructions': _careInstructions,
          'updatedAt': now,
        };
        
        if (widget.isEditing && widget.plant != null) {
          // Update existing plant
          await firestore.collection('plants').doc(widget.plant!.id).update(plantData);
        } else {
          // Create new plant
          plantData['createdAt'] = now;
          await firestore.collection('plants').add(plantData);
        }
        
        if (mounted) {
          Navigator.pop(context, true); // Return success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Tanaman' : 'Tambah Tanaman';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF4CAF50),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4CAF50)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information Section
                    const Text(
                      'Informasi Dasar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nama Tanaman',
                      hint: 'Masukkan nama tanaman',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tanaman tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _scientificNameController,
                      label: 'Nama Ilmiah',
                      hint: 'Masukkan nama ilmiah (Latin)',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Deskripsi',
                      hint: 'Masukkan deskripsi tanaman',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Deskripsi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _imageUrlController,
                      label: 'URL Gambar',
                      hint: 'Masukkan URL gambar tanaman',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'URL Gambar tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFE8F5E9),
                      ),
                      items: AppConstants.plantCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Growing Information Section
                    const Text(
                      'Informasi Pertumbuhan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _growthDurationController,
                      label: 'Durasi Pertumbuhan (hari)',
                      hint: 'Masukkan durasi pertumbuhan dalam hari',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    // Difficulty dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      decoration: InputDecoration(
                        labelText: 'Tingkat Kesulitan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFE8F5E9),
                      ),
                      items: ['Mudah', 'Sedang', 'Sulit'].map((difficulty) {
                        return DropdownMenuItem<String>(
                          value: difficulty,
                          child: Text(difficulty),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDifficulty = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _wateringFrequencyController,
                      label: 'Frekuensi Penyiraman',
                      hint: 'Misal: Setiap 2-3 hari',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _sunlightRequirementController,
                      label: 'Kebutuhan Sinar Matahari',
                      hint: 'Misal: Sinar matahari penuh',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _soilTypeController,
                      label: 'Jenis Tanah',
                      hint: 'Misal: Tanah gembur kaya humus',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _harvestTimeController,
                      label: 'Waktu Panen',
                      hint: 'Misal: 75-90 hari setelah tanam',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _benefitsController,
                      label: 'Manfaat',
                      hint: 'Masukkan manfaat tanaman',
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Planting Steps Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Langkah-langkah Penanaman',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF4CAF50),
                          ),
                          onPressed: _addEmptyPlantingStep,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._plantingSteps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      return _buildPlantingStepField(index, step);
                    }).toList(),
                    
                    const SizedBox(height: 24),
                    
                    // Care Instructions Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Instruksi Perawatan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF4CAF50),
                          ),
                          onPressed: _addEmptyCareInstruction,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._careInstructions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final instruction = entry.value;
                      return _buildCareInstructionField(index, instruction);
                    }).toList(),
                    
                    const SizedBox(height: 32),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _savePlant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.isEditing ? 'Simpan Perubahan' : 'Tambah Tanaman',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: const Color(0xFFE8F5E9),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
  
  Widget _buildPlantingStepField(int index, Map<String, dynamic> step) {
    final titleController = TextEditingController(text: step['title']);
    final descriptionController = TextEditingController(text: step['description']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Langkah ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () => _removePlantingStep(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Judul Langkah',
                hintText: 'Misal: Persiapan Benih',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFE8F5E9),
              ),
              onChanged: (value) {
                setState(() {
                  _plantingSteps[index]['title'] = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Deskripsi Langkah',
                hintText: 'Masukkan deskripsi langkah',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFE8F5E9),
              ),
              maxLines: 2,
              onChanged: (value) {
                setState(() {
                  _plantingSteps[index]['description'] = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCareInstructionField(int index, Map<String, dynamic> instruction) {
    final titleController = TextEditingController(text: instruction['title']);
    final descriptionController = TextEditingController(text: instruction['description']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Instruksi ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () => _removeCareInstruction(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Judul Instruksi',
                hintText: 'Misal: Penyiraman',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFE8F5E9),
              ),
              onChanged: (value) {
                setState(() {
                  _careInstructions[index]['title'] = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Deskripsi Instruksi',
                hintText: 'Masukkan deskripsi instruksi',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFE8F5E9),
              ),
              maxLines: 2,
              onChanged: (value) {
                setState(() {
                  _careInstructions[index]['description'] = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}